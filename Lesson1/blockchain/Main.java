package Lesson1.blockchain;

public class Main {
    public static void main(String[] args) {
        Blockchain blockchain = new Blockchain();

        // 创世区块
        Block genesis = new Block("Genesis Block", "0");
        genesis.mineBlock(Blockchain.difficulty);
        blockchain.chain.add(genesis);

        // 第二个区块
        Block block1 = new Block("Transaction Data 1", blockchain.getLatestBlock().hash);
        block1.mineBlock(Blockchain.difficulty);
        blockchain.addBlock(block1);

        // 第三个区块
        Block block2 = new Block("Transaction Data 2", blockchain.getLatestBlock().hash);
        block2.mineBlock(Blockchain.difficulty);
        blockchain.addBlock(block2);

        System.out.println("Blockchain valid? " + blockchain.isChainValid());
        for (Block block : blockchain.chain) {
            System.out.println("Block Hash: " + block.hash);
        }
    }
}