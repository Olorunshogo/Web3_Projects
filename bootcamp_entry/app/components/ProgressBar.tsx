
interface Props {
  progress: number;
}

export function ProgressBar({ progress }: Props) {
  return (
    <div className="w-full h-8 mb-12 overflow-hidden bg-gray-200 rounded-full">
      <div
        className="h-full transition-all duration-1000 ease-out bg-primary"
        style={{ width: `${progress}%` }}
      />
    </div>
  );
}
