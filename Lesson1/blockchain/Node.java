package Lesson1.blockchain;

import java.io.*;
import java.net.*;

public class Node {
    private Blockchain blockchain;

    public Node(Blockchain blockchain) {
        this.blockchain = blockchain;
    }

    // 向其他节点广播新区块
    public void broadcastBlock(Block newBlock, String host, int port) throws IOException {
        try (Socket socket = new Socket(host, port)) {
            ObjectOutputStream out = new ObjectOutputStream(socket.getOutputStream());
            out.writeObject(newBlock);
        }
    }

    // 接收区块
    public void startServer(int port) throws IOException, ClassNotFoundException {
        ServerSocket serverSocket = new ServerSocket(port);
        while (true) {
            Socket socket = serverSocket.accept();
            ObjectInputStream in = new ObjectInputStream(socket.getInputStream());
            Block receivedBlock = (Block) in.readObject();
            blockchain.addBlock(receivedBlock);
        }
    }
}