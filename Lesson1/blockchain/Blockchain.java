package Lesson1.blockchain;


import java.util.LinkedList;


public class Blockchain {
    public static int difficulty = 4; // 工作量证明难度
    public LinkedList<Block> chain = new LinkedList<>();

    public void addBlock(Block block) {
        if (isValidNewBlock(block, getLatestBlock())) {
            chain.add(block);
        } else {
            System.out.println("Invalid block");
        }
    }

    public Block getLatestBlock() {
        return chain.get(chain.size() - 1);
    }

    public boolean isValidNewBlock(Block newBlock, Block previousBlock) {
        if (!newBlock.previousHash.equals(previousBlock.hash)) {
            //检查前一个区块哈希是否匹配：确保新区块链接的是正确的上一个区块；
            return false;
        } else if (!newBlock.calculateHash().equals(newBlock.hash)) {
            //检查当前区块哈希是否正确：验证区块数据未被篡改；
            return false;
        } else if (newBlock.timestamp <= previousBlock.timestamp) {
            //检查时间戳是否合理：确保新区块的时间戳大于上一个区块。
            return false;
        } else {
            return true;
        }
    }

    public boolean isChainValid() {
        for (int i = 1; i < chain.size(); i++) {
            Block currentBlock = chain.get(i);
            Block previousBlock = chain.get(i - 1);

            if (!currentBlock.hash.equals(currentBlock.calculateHash())) {
                return false;
            }

            if (!currentBlock.previousHash.equals(previousBlock.hash)) {
                return false;
            }
        }
        return true;
    }
}