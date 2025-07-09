package Lesson1.blockchain;

import java.util.Arrays;
import java.util.List;

public class Main {
    public static void main(String[] args) {
        Blockchain blockchain = new Blockchain();

        // 创世区块
        List<Transaction> txs1 = Arrays.asList(new Transaction("Alice", "Bob", 5));

        Block genesis = new Block(0, txs1, "0");
        genesis.mineBlock(Blockchain.difficulty);
        blockchain.chain.add(genesis);

        // 第二个区块
        List<Transaction> txs2 = Arrays.asList(new Transaction("Alice", "Bob", 2));
        Block block1 = new Block(blockchain.chain.size(), txs2, blockchain.getLatestBlock().hash);
        block1.mineBlock(Blockchain.difficulty);
        blockchain.addBlock(block1);

        // 第三个区块
        List<Transaction> txs3 = Arrays.asList(new Transaction("Alice", "Bob", 1));
        Block block2 = new Block(blockchain.chain.size(), txs3, blockchain.getLatestBlock().hash);
        block2.mineBlock(Blockchain.difficulty);
        blockchain.addBlock(block2);

        System.out.println("Blockchain valid? " + blockchain.isChainValid());
        for (Block block : blockchain.chain) {
            System.out.println("Block Hash: " + block.hash);
        }
    }
}