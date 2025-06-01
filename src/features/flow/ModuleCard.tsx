import React from "react";
import { useDrag } from "react-dnd";
import { ChevronDownIcon, ChevronUpIcon } from '@heroicons/react/24/solid';
import { LockClosedIcon } from '@heroicons/react/24/solid';

interface ModuleCardProps {
  title: string;
  features: string[];
  isLocked: boolean;
  expanded: boolean;
  toggleExpand: () => void;
  source: "available" | "active";
}

const ModuleCard: React.FC<ModuleCardProps> = ({
  title,
  features,
  isLocked,
  expanded,
  toggleExpand,
  source,
}) => {
  const [{ isDragging }, drag] = useDrag(
    () => ({
      type: "MODULE",
      item: { title, from: source },
      canDrag: () => !isLocked,
      collect: (monitor) => ({
        isDragging: monitor.isDragging(),
      }),
    }),
    [isLocked, source]
  );

  return drag(
    <div
      className={`bg-white border rounded-2xl shadow p-4 transition-all ${
        isLocked ? "opacity-80 cursor-default" : "cursor-move"
      } ${isDragging ? "opacity-30" : ""}`}
    >
        <div className="flex justify-between items-center" onClick={toggleExpand}>
            <h3 className="font-bold text-lg flex items-center gap-2">
            {title}
            {isLocked && <LockClosedIcon className="w-5 h-5 text-gray-500" />}
            </h3>
            {expanded ? (
            <ChevronUpIcon className="w-5 h-5" />
            ) : (
            <ChevronDownIcon className="w-5 h-5" />
            )}
        </div>
      {expanded && (
        <div className="mt-2 space-y-1">
          {features.map((f) => (
            <label key={f} className="flex gap-2 items-center">
              <input type="checkbox" className="form-checkbox" /> {f}
            </label>
          ))}
        </div>
      )}
    </div>
  );
};

export default ModuleCard;
