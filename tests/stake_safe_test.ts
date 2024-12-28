import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure can stake tokens",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get('wallet_1')!;
    const amount = 2000;
    const lockPeriod = 150;

    let block = chain.mineBlock([
      Tx.contractCall('stake-safe', 'stake', [
        types.uint(amount),
        types.uint(lockPeriod)
      ], wallet_1.address)
    ]);

    block.receipts[0].result.expectOk();
    
    // Verify stake
    let stakeBlock = chain.mineBlock([
      Tx.contractCall('stake-safe', 'get-stake', [
        types.principal(wallet_1.address)
      ], wallet_1.address)
    ]);

    const stake = stakeBlock.receipts[0].result.expectSome();
    assertEquals(stake['amount'], types.uint(amount));
  },
});

Clarinet.test({
  name: "Cannot withdraw before lock period",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get('wallet_1')!;
    const amount = 2000;
    const lockPeriod = 150;

    let block = chain.mineBlock([
      Tx.contractCall('stake-safe', 'stake', [
        types.uint(amount), 
        types.uint(lockPeriod)
      ], wallet_1.address),
      
      Tx.contractCall('stake-safe', 'withdraw', [
        types.uint(amount)
      ], wallet_1.address)
    ]);

    block.receipts[0].result.expectOk();
    block.receipts[1].result.expectErr(types.uint(102)); // err-stake-not-mature
  },
});

Clarinet.test({
  name: "Can withdraw after lock period",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get('wallet_1')!;
    const amount = 2000;
    const lockPeriod = 150;

    let block = chain.mineBlock([
      Tx.contractCall('stake-safe', 'stake', [
        types.uint(amount),
        types.uint(lockPeriod)
      ], wallet_1.address)
    ]);

    // Mine blocks to pass lock period
    chain.mineEmptyBlockUntil(block.height + lockPeriod + 1);

    let withdrawBlock = chain.mineBlock([
      Tx.contractCall('stake-safe', 'withdraw', [
        types.uint(amount)
      ], wallet_1.address)
    ]);

    withdrawBlock.receipts[0].result.expectOk();
  },
});

Clarinet.test({
  name: "Can claim rewards",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get('wallet_1')!;
    const amount = 2000;
    const lockPeriod = 150;

    let block = chain.mineBlock([
      Tx.contractCall('stake-safe', 'stake', [
        types.uint(amount),
        types.uint(lockPeriod)
      ], wallet_1.address)
    ]);

    // Mine some blocks
    chain.mineEmptyBlockUntil(block.height + 200);

    let rewardsBlock = chain.mineBlock([
      Tx.contractCall('stake-safe', 'claim-rewards', [], wallet_1.address)
    ]);

    rewardsBlock.receipts[0].result.expectOk();
  },
});