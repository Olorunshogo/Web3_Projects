
"use client";

import { useState, useEffect } from "react";

interface TimeLeft {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
}

interface Props {
  targetDate: string;
  launched: boolean;
}

export function CountdownTimer({ targetDate, launched }: Props) {
  const [timeLeft, setTimeLeft] = useState<TimeLeft>({
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0,
  });

  useEffect(() => {
    if (launched) return;

    const calculate = () => {
      const target = new Date(targetDate).getTime();
      const now = Date.now();
      const diff = target - now;

      if (diff <= 0) {
        setTimeLeft({ days: 0, hours: 0, minutes: 0, seconds: 0 });
        return;
      }

      const days = Math.floor(diff / (1000 * 60 * 60 * 24));
      const hours = Math.floor(
        (diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
      );
      const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((diff % (1000 * 60)) / 1000);

      setTimeLeft({ days, hours, minutes, seconds });
    };

    calculate();
    const interval = setInterval(calculate, 1000);
    return () => clearInterval(interval);
  }, [targetDate, launched]);

  if (launched) {
    return (
      <div className="py-20">
        <p className="text-5xl font-bold md:text-7xl text-primary">
          🚀 Launched!
        </p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-4 gap-4 mb-12 md:gap-8">
      {Object.entries(timeLeft).map(([unit, value]) => (
        <div key={unit} className="text-center">
          <p className="text-5xl font-bold md:text-7xl text-primary">
            {String(value).padStart(2, "0")}
          </p>
          <p className="mt-2 text-lg text-gray-600 uppercase">{unit}</p>
        </div>
      ))}
    </div>
  );
}
