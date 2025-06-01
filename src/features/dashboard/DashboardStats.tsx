import React from 'react';

interface DashboardStatsProps {
  title: string;
  icon: React.ReactNode;
  value: string | number;
  description: string;
  colorIndex?: number; // optional, fallback below
}

const COLORS = [
  "text-blue-600",    // info
  "text-green-600",   // success
  "text-yellow-500",  // warning
  "text-red-500",     // danger
  "text-purple-600",  // custom
];

const DashboardStats: React.FC<DashboardStatsProps> = ({
  title,
  icon,
  value,
  description,
  colorIndex = 0,
}) => {
  const descStyle =
    description.includes("↗︎")
      ? "font-bold text-green-600"
      : description.includes("↙")
      ? "font-bold text-red-500"
      : "text-gray-600";

  return (
    <div
      className="stats shadow bg-white rounded-lg p-4 flex-1 min-w-[220px] max-w-[320px]"
      style={{ flexBasis: "280px" }}
    >
      <div className="stat flex items-center gap-4">
        <div
          className={`stat-figure text-4xl ${COLORS[colorIndex % COLORS.length]}`}
          aria-label={`${title} icon`}
        >
          {icon}
        </div>
        <div>
          <div className="stat-title text-gray-500">{title}</div>
          <div className="stat-value text-3xl font-extrabold">{value}</div>
          <div className={`stat-desc mt-1 ${descStyle}`}>{description}</div>
        </div>
      </div>
    </div>
  );
};

export default DashboardStats;
