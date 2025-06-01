import React from "react";
import { useDrop } from "react-dnd";
import ModuleCard from "./ModuleCard";

interface ModuleColumnProps {
  title: string;
  modules: string[];
  onDrop: (title: string) => void;
  lockedModules: string[];
  expanded: Record<string, boolean>;
  toggleExpand: (title: string) => void;
  modulesData: Record<string, string[]>;
  source: "available" | "active";
}

const ModuleColumn: React.FC<ModuleColumnProps> = ({
  title,
  modules,
  onDrop,
  lockedModules,
  expanded,
  toggleExpand,
  modulesData,
  source,
}) => {
  const [, drop] = useDrop(() => ({
    accept: "MODULE",
    drop: (item: { title: string; from: string }) => {
      if (item.from !== source) {
        onDrop(item.title);
      }
    },
  }));

  return drop(
    <div className="w-1/2 p-4">
      <h2 className="text-xl font-semibold mb-2 text-center">{title}</h2>
      <div className="bg-gray-100 rounded-xl min-h-[400px] p-4 space-y-4">
        {modules.map((m) => (
          <ModuleCard
            key={m}
            title={m}
            features={modulesData[m]}
            isLocked={lockedModules.includes(m)}
            expanded={expanded[m] ?? false}
            toggleExpand={() => toggleExpand(m)}
            source={source}
          />
        ))}
      </div>
    </div>
  );
};

export default ModuleColumn;
