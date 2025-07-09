package Lesson1.blockchain;

public class Transaction {
    String sender;
    String recipient;
    int amount;

    public Transaction(String sender, String recipient, int amount) {
        this.sender = sender;
        this.recipient = recipient;
        this.amount = amount;
    }
}
