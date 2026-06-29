"use client";

import { useState, useEffect, useRef } from "react";
import { CountdownTimer } from "../components/CountdownTimer";
import { ProgressBar } from "../components/ProgressBar";
import { SubscribeForm } from "../components/SubscribeForm";

export default function LaunchTimer() {
  // Default launch date: Jan 31, 2026 (future relative to current date Jan 10, 2026)
  const [targetDate, setTargetDate] = useState<string>("2026-01-31T00:00");
  const [launched, setLaunched] = useState<boolean>(false);
  const [progress, setProgress] = useState<number>(0);

  const initialDistance = useRef<number | null>(null);

  // Recalculate initial distance and reset states when target changes
  useEffect(() => {
    const targetTime = new Date(targetDate).getTime();
    if (!isNaN(targetTime)) {
      const dist = targetTime - Date.now();
      if (dist <= 0) {
        // Queue state updates to avoid synchronous calls in effect body
        setTimeout(() => {
          setLaunched(true);
          setProgress(100);
        }, 0);
      } else {
        initialDistance.current = dist;
        setTimeout(() => {
          setLaunched(false);
          setProgress(0); // Reset progress for new future date
        }, 0);
      }
    }
  }, [targetDate]);

  // Timer for progress updates
  useEffect(() => {
    if (launched) return;

    const interval = setInterval(() => {
      const targetTime = new Date(targetDate).getTime();
      const remaining = targetTime - Date.now();

      if (remaining <= 0) {
        setLaunched(true);
        setProgress(100);
        clearInterval(interval);
      } else if (initialDistance.current) {
        const prog =
          ((initialDistance.current - remaining) / initialDistance.current) *
          100;
        setProgress(Math.min(100, prog));
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [targetDate, launched]);

  return (
    <>
      <h1 className="mb-8 text-3xl font-bold text-center md:text-4xl">
        Token Launch Countdown
      </h1>

      <div className="p-8 text-center bg-white shadow-lg rounded-xl">
        {/* Date picker */}
        <div className="mb-10">
          <label className="block mb-2 text-lg font-medium">
            Set Launch Date & Time
          </label>
          <input
            type="datetime-local"
            value={targetDate}
            onChange={(e) => setTargetDate(e.target.value)}
            className="px-4 py-2 text-lg border border-gray-300 rounded-lg"
          />
        </div>

        {/* Countdown or Launched message */}
        <CountdownTimer targetDate={targetDate} launched={launched} />

        {/* Progress bar */}
        <ProgressBar progress={progress} />

        {/* Subscribe form */}
        <SubscribeForm />
      </div>
    </>
  );
}
