import express from 'express'
import dotenv from 'dotenv'
import mysql from 'mysql2/promise'
import { createPublicClient, http, decodeEventLog } from 'viem'
import { sepolia } from 'viem/chains'
import { abi as erc20Abi } from './ERC20ABI.js'
import path from 'path'
import { fileURLToPath } from 'url'

dotenv.config()

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const app = express()

// 创建 MySQL 连接池
const pool = mysql.createPool({
  host: process.env.MYSQL_HOST,
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD,
  database: process.env.MYSQL_DATABASE,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
})



const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(process.env.RPC_URL)
})

const tokenAddress = process.env.TOKEN_ADDRESS.trim().toLowerCase()

// 扫描并存储转账日志
async function fetchPastLogs() {
  const logs = await publicClient.getLogs({
    address: tokenAddress,
    event: {
      type: 'event',
      name: 'Transfer',
      inputs: [
        { indexed: true, name: 'from', type: 'address' },
        { indexed: true, name: 'to', type: 'address' },
        { indexed: false, name: 'value', type: 'uint256' }
      ]
    },
    fromBlock: 0n,
    toBlock: 'latest'
  })

  const conn = await pool.getConnection()
  let inserted = 0

  try {
    for (const log of logs) {
      const { args } = decodeEventLog({ abi: erc20Abi, data: log.data, topics: log.topics })
      const block = await publicClient.getBlock({ blockHash: log.blockHash })

      // 使用 INSERT IGNORE 避免重复插入相同 tx_hash
      const [result] = await conn.query(`
        INSERT IGNORE INTO transfers (from_address, to_address, amount, tx_hash, block_number, timestamp)
        VALUES (?, ?, ?, ?, ?, ?)
      `, [
        args.from.toLowerCase(),
        args.to.toLowerCase(),
        args.value.toString(),
        log.transactionHash,
        Number(log.blockNumber),
        Number(block.timestamp)
      ])

      if (result.affectedRows > 0) inserted++
    }
  } finally {
    conn.release()
  }

  return inserted
}

// 扫描接口（前端点击触发）
app.get('/api/scan', async (req, res) => {
  try {
    const count = await fetchPastLogs()
    res.json({ success: true, count })
  } catch (err) {
    res.status(500).json({ success: false, error: err.message })
  }
})

// 查询某地址转账记录接口
app.get('/api/transfers/:address', async (req, res) => {
  const addr = req.params.address.toLowerCase()
  try {
    const [rows] = await pool.query(
      `SELECT * FROM transfers WHERE from_address = ? OR to_address = ? ORDER BY block_number DESC`,
      [addr, addr]
    )
    res.json(rows)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

// 提供静态前端页面
app.use(express.static(path.join(__dirname, 'public')))

// 启动服务器（不自动扫描）
app.listen(3000, () => {
  console.log('🚀 Server running on http://localhost:3000')
})
