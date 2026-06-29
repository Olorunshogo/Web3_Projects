'use client';

import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { parseEther, formatEther } from 'viem';
import { CONTRACT_ADDRESS, CONTRACT_ABI } from '@/lib/config';

export default function Home() {
  const { address, isConnected } = useAccount();
  const [depositAmount, setDepositAmount] = useState('');
  const [lockDays, setLockDays] = useState('1');
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, []);

  const { data: vaultData, refetch: refetchVault } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: CONTRACT_ABI,
    functionName: 'getVault',
    args: address ? [address] : undefined,
    query: {
      enabled: !!address,
    },
  });

  const { writeContract: deposit, data: depositHash } = useWriteContract();
  const { writeContract: withdraw, data: withdrawHash } = useWriteContract();

  const { isLoading: isDepositLoading, isSuccess: isDepositSuccess } = useWaitForTransactionReceipt(
    {
      hash: depositHash,
    },
  );

  const { isLoading: isWithdrawLoading, isSuccess: isWithdrawSuccess } =
    useWaitForTransactionReceipt({
      hash: withdrawHash,
    });

  useEffect(() => {
    if (isDepositSuccess || isWithdrawSuccess) {
      refetchVault();
    }
  }, [isDepositSuccess, isWithdrawSuccess, refetchVault]);

  const vault = vaultData
    ? {
        amount: formatEther(vaultData[0]),
        unlockTime: Number(vaultData[1]),
        active: vaultData[2],
      }
    : null;

  const handleDeposit = () => {
    if (!depositAmount) return;
    const unlockTime = Math.floor(Date.now() / 1000) + Number(lockDays) * 86400;
    deposit({
      address: CONTRACT_ADDRESS,
      abi: CONTRACT_ABI,
      functionName: 'deposit',
      args: [BigInt(unlockTime)],
      value: parseEther(depositAmount),
    });
  };

  const handleWithdraw = () => {
    withdraw({
      address: CONTRACT_ADDRESS,
      abi: CONTRACT_ABI,
      functionName: 'withdraw',
    });
  };

  const isUnlocked = vault && vault.active && now / 1000 >= vault.unlockTime;
  const isLoading = isDepositLoading || isWithdrawLoading;

  return (
    <div className="min-h-screen bg-black p-4 sm:p-8 text-white">
      <div className="max-w-2xl mx-auto">
        {/* Header */}
        <div className="flex flex-col sm:flex-row justify-between items-center mb-8 gap-4">
          <div className="text-center sm:text-left">
            <h1 className="text-4xl sm:text-5xl font-extrabold text-white drop-shadow-lg">
              🔐 TimeLock
            </h1>
            <p className="text-white/70 mt-1 font-medium">Secure Your ETH • Earn Rewards</p>
          </div>
          <div className="bg-white/20 backdrop-blur-lg rounded-full p-1">
            <ConnectButton />
          </div>
        </div>

        {/* Main Card */}
        {!isConnected ? (
          <div className="bg-white/10 backdrop-blur-xl rounded-3xl shadow-2xl border border-white/20 p-8 sm:p-12 text-center">
            <div className="w-24 h-24 mx-auto mb-6 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-full flex items-center justify-center shadow-lg">
              <span className="text-5xl">🦊</span>
            </div>
            <h2 className="text-3xl font-bold text-white mb-4">Welcome to TimeLock!</h2>
            <p className="text-white/70 text-lg mb-6">
              Connect your wallet to start locking your ETH and earning secure returns.
            </p>
            <div className="inline-block bg-white/10 rounded-full px-8 py-3 text-white font-bold shadow-lg hover:bg-white/20 transform hover:scale-105 transition-all">
              <ConnectButton showBalance={false} />
            </div>

            {/* Features */}
            <div className="mt-10 grid grid-cols-1 sm:grid-cols-3 gap-4">
              <div className="bg-white/10 rounded-2xl p-4">
                <div className="text-3xl mb-2">🔒</div>
                <p className="text-white font-semibold">Secure</p>
                <p className="text-white/70 text-sm">Bank-grade security</p>
              </div>
              <div className="bg-white/10 rounded-2xl p-4">
                <div className="text-3xl mb-2">⚡</div>
                <p className="text-white font-semibold">Fast</p>
                <p className="text-white/70 text-sm">Instant deposits</p>
              </div>
              <div className="bg-white/10 rounded-2xl p-4">
                <div className="text-3xl mb-2">🎯</div>
                <p className="text-white font-semibold">Flexible</p>
                <p className="text-white/70 text-sm">Choose your lock period</p>
              </div>
            </div>
          </div>
        ) : (
          <div className="space-y-6">
            {vault && vault.active ? (
              <div className="bg-white/10 backdrop-blur-xl rounded-3xl shadow-2xl border border-white/20 p-6 sm:p-8">
                <div className="flex items-center justify-between mb-6">
                  <h2 className="text-2xl sm:text-3xl font-bold text-white">Your Vault</h2>
                  <span
                    className={`px-4 py-2 rounded-full font-bold text-sm ${
                      isUnlocked
                        ? 'bg-green-400 text-green-900 animate-pulse'
                        : 'bg-yellow-400 text-yellow-900'
                    }`}
                  >
                    {isUnlocked ? '✓ UNLOCKED' : '🔒 LOCKED'}
                  </span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 mb-6">
                  <div className="bg-white/5 rounded-2xl p-5 border border-white/10">
                    <p className="text-white/70 text-sm font-medium">Locked Amount</p>
                    <p className="text-3xl sm:text-4xl font-extrabold text-white mt-1">
                      {vault.amount} <span className="text-lg text-white/70">ETH</span>
                    </p>
                  </div>
                  <div className="bg-white/5 rounded-2xl p-5 border border-white/10">
                    <p className="text-white/70 text-sm font-medium">Unlock Date</p>
                    <p className="text-xl font-bold text-white mt-1">
                      {new Date(vault.unlockTime * 1000).toLocaleDateString()}
                    </p>
                    <p className="text-white/70 text-sm">
                      {new Date(vault.unlockTime * 1000).toLocaleTimeString()}
                    </p>
                  </div>
                </div>

                {/* Progress Bar */}
                <div className="mb-6">
                  <div className="flex justify-between text-white text-sm mb-2">
                    <span>Time Progress</span>
                    <span>
                      {vault.unlockTime > 0
                        ? Math.min(
                            100,
                            Math.max(
                              0,
                              (1 -
                                (vault.unlockTime * 1000 - now) /
                                  (Number(lockDays) * 86400 * 1000)) *
                                100,
                            ),
                          ).toFixed(0)
                        : 0}
                      %
                    </span>
                  </div>
                  <div className="h-3 bg-white/20 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-white/30 rounded-full transition-all duration-500"
                      style={{ width: isUnlocked ? '100%' : '30%' }}
                    />
                  </div>
                </div>

                <button
                  onClick={handleWithdraw}
                  disabled={!isUnlocked || isLoading}
                  className={`w-full py-4 rounded-2xl font-bold text-lg transition-all transform ${
                    isUnlocked && !isLoading
                      ? 'bg-linear-to-r from-green-400 to-emerald-500 hover:from-green-500 hover:to-emerald-600 text-white shadow-lg hover:shadow-xl hover:scale-[1.02]'
                      : 'bg-white/20 text-white/50 cursor-not-allowed'
                  }`}
                >
                  {isLoading ? (
                    <span className="flex items-center justify-center gap-2">
                      <span className="animate-spin">⏳</span> Processing...
                    </span>
                  ) : isUnlocked ? (
                    '💰 Withdraw ETH'
                  ) : (
                    '🔒 Locked - Wait for unlock'
                  )}
                </button>
              </div>
            ) : (
              <div className="bg-white/10 backdrop-blur-xl rounded-3xl shadow-2xl border border-white/20 p-6 sm:p-8">
                <div className="text-center mb-8">
                  <div className="w-20 h-20 mx-auto mb-4 bg-white/10 rounded-2xl flex items-center justify-center shadow-lg">
                    <span className="text-4xl">🚀</span>
                  </div>
                  <h2 className="text-2xl sm:text-3xl font-bold text-white">Create Your Vault</h2>
                  <p className="text-white/70 mt-2">Lock your ETH and earn secure returns</p>
                </div>

                <div className="space-y-6">
                  <div>
                    <label className="block text-white font-semibold mb-3">💵 Amount (ETH)</label>
                    <div className="relative">
                      <input
                        type="number"
                        step="0.01"
                        min="0"
                        value={depositAmount}
                        onChange={(e) => setDepositAmount(e.target.value)}
                        className="w-full px-5 py-4 bg-white/10 border border-white/20 rounded-2xl text-white placeholder-white/50 text-lg focus:outline-none focus:ring-2 focus:ring-white/50 focus:border-transparent backdrop-blur-sm"
                        placeholder="0.00"
                      />
                      <span className="absolute right-5 top-1/2 -translate-y-1/2 text-white/70 font-bold">
                        ETH
                      </span>
                    </div>
                  </div>

                  <div>
                    <label className="block text-white font-semibold mb-3">
                      📅 Lock Duration (Days)
                    </label>
                    <div className="grid grid-cols-4 gap-2">
                      {[1, 7, 30, 90].map((days) => (
                        <button
                          key={days}
                          onClick={() => setLockDays(days.toString())}
                          className={`py-3 rounded-xl font-bold transition-all ${
                            lockDays === days.toString()
                              ? 'bg-white/20 text-white shadow-lg'
                              : 'bg-white/10 text-white/70 hover:bg-white/20'
                          }`}
                        >
                          {days}D
                        </button>
                      ))}
                    </div>
                    <input
                      type="number"
                      min="1"
                      value={lockDays}
                      onChange={(e) => setLockDays(e.target.value)}
                      className="w-full mt-3 px-5 py-4 bg-white/10 border border-white/20 rounded-2xl text-white placeholder-white/50 focus:outline-none focus:ring-2 focus:ring-white/50 backdrop-blur-sm"
                      placeholder="Custom days"
                    />
                  </div>

                  <button
                    onClick={handleDeposit}
                    disabled={!depositAmount || isLoading}
                    className="w-full py-4 rounded-2xl font-bold text-lg bg-white/10 hover:bg-white/20 text-white shadow-lg hover:shadow-xl transform hover:scale-[1.02] transition-all disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
                  >
                    {isLoading ? (
                      <span className="flex items-center justify-center gap-2">
                        <span className="animate-spin">⏳</span> Processing Transaction...
                      </span>
                    ) : (
                      '🔐 Lock ETH'
                    )}
                  </button>
                </div>
              </div>
            )}

            {/* Info Card */}
            <div className="bg-white/5 backdrop-blur-xl rounded-2xl p-6 border border-white/10">
              <h3 className="text-white font-bold text-lg mb-3">💡 How it works</h3>
              <ul className="space-y-2 text-white/70">
                <li className="flex items-start gap-2">
                  <span className="text-white/70">1.</span>
                  Deposit your ETH and choose a lock period
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-white/70">2.</span>
                  Your ETH is locked securely in the smart contract
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-white/70">3.</span>
                  After the lock period, withdraw your ETH anytime
                </li>
              </ul>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
