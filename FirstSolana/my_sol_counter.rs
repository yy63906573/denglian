use anchor_lang::prelude::*;

declare_id!("5PWsRWWngVphwhdxFHbNwiPX6wpH6RmyK1X4ucXR8Ghe");

#[program]
pub mod my_sol_counter {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let counter_account = &mut ctx.accounts.counter_account;
        counter_account.count = 0;
        msg!("Counter initialized to 0!");
        Ok(())
    }

    pub fn increment(ctx: Context<Increment>) -> Result<()> {
        let counter_account = &mut ctx.accounts.counter_account;
        counter_account.count += 1;
        msg!("Counter incremented to {}!", counter_account.count);
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = signer,
        space = 8 + 8, // 8 bytes for discriminator + 8 bytes for u64 count
        seeds = [b"counter"], // 使用 "counter" 作为种子
        bump
    )]
    pub counter_account: Account<'info, Counter>,
    #[account(mut)]
    pub signer: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct Increment<'info> {
    #[account(
        mut,
        seeds = [b"counter"],
        bump,
    )]
    pub counter_account: Account<'info, Counter>,
}

#[account]
pub struct Counter {
    pub count: u64,
}
