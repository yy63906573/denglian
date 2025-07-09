package Lesson1.blockchain;

import java.util.Date;
import java.util.List;

/**
 * 区块类，包含区块的基本属性和方法
 * 包括区块哈希、前一个区块哈希、交易数据、时间戳和工作量证明的 nonce 值
 * 提供计算哈希、挖矿和验证区块的方法
 */
public class Block {
    private int index;
    public long timestamp;
    private List<Transaction> transactions;
    private int nonce;
    String previousHash;
    public String hash;

    public Block(int index, List<Transaction> transactions, String previousHash) {
        this.index = index;
        this.transactions = transactions;
        this.previousHash = previousHash;
        this.timestamp = new Date().getTime();
        this.nonce = 0;
        this.hash = calculateHash();
    }


    /**
     * 计算区块的哈希值
     * 
     * @return
     */
    public String calculateHash() {
        String input = index + previousHash +
                Long.toString(timestamp) +
                Integer.toString(nonce) +
                transactionsToString(transactions);
        return StringUtil.applySha256(input);
    }

    /**
     * 将交易列表转换为字符串
     * 用于计算区块哈希
     * 
     * @param txs
     * @return
     */
    public String transactionsToString(List<Transaction> txs) {
        StringBuilder sb = new StringBuilder();
        for (Transaction tx : txs) {
            sb.append(tx.sender).append(tx.recipient).append(tx.amount);
        }
        return sb.toString();
    }

    /**
     * 挖矿方法
     * 根据给定的难度值进行工作量证明
     * 不断增加 nonce 值，直到找到满足条件的哈希值
     * 
     * @param difficulty 工作量证明的难度
     */
    public void mineBlock(int difficulty) {
        // 创建目标字符串
        String target = new String(new char[difficulty]).replace('\0', '0');
        while (!hash.substring(0, difficulty).equals(target)) {
            nonce++;
            hash = calculateHash();
        }
        // System.out.println("Block mined: " + hash);
    }
}