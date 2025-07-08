package Lesson1;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class ProofOfWork {
    // 计算SHA-256哈希
    public static String sha256(String input) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");

            byte[] hash = digest.digest(input.getBytes());
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if(hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch(NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    // 挖矿的过程
    public static void wankuang(String nickname, int zeroCount) {
        long startTime = System.currentTimeMillis();
        int nonce = 0;
        String prefix = "0".repeat(zeroCount);
        String hash = "";
        String content = "";
        while (true) {
            content = nickname + nonce;
            hash = sha256(content);
           // System.out.println("Hash: " + hash);
            if (hash.startsWith(prefix)) {
                long endTime = System.currentTimeMillis();
                System.out.println("满足 " + zeroCount + " 个 0 前缀的哈希值：");
                System.out.println("耗时: " + (endTime - startTime) + " ms");
                System.out.println("内容: " + content);
                System.out.println("Hash: " + hash);
                System.out.println();
                break;
            }
            nonce++;
        }
    }


    public static void main(String[] args) {
        //昵称
        String nickname = "yy6390673";
        wankuang(nickname, 5);
        wankuang(nickname, 5);
       
    }
}