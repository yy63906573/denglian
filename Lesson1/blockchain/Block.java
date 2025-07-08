package Lesson1.blockchain;

import java.util.Date;
/**
 * 区块类，包含区块的基本属性和方法
 * 包括区块哈希、前一个区块哈希、交易数据、时间戳和工作量证明的 nonce 值
 * 提供计算哈希、挖矿和验证区块的方法
 */
public class Block {
    // 区块属性
    public String hash;
    // 前一个区块的哈希
    // 用于链接区块，形成区块链
    public String previousHash;
    // 交易数据
    private String data;
    // 时间戳
    public long timestamp;
    // 工作量证明的 nonce 值
    // 用于挖矿过程中的计算
    public int nonce;

    public Block(String data, String previousHash) {
        this.data = data;
        this.previousHash = previousHash;
        this.timestamp = new Date().getTime();
        this.hash = calculateHash();
    }

    /**
     * 计算区块的哈希值
     * @return
     */
    public String calculateHash() {
        String calculatedHash = StringUtil.applySha256(
                previousHash +
                        Long.toString(timestamp) +
                        Integer.toString(nonce) +
                        data
        );
        return calculatedHash;
    }

    /**
     * 挖矿方法
     * 根据给定的难度值进行工作量证明
     * 不断增加 nonce 值，直到找到满足条件的哈希值
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