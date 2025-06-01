import React, { useState, useEffect } from "react";
import { DndProvider } from "react-dnd";
import { HTML5Backend } from "react-dnd-html5-backend";
import ModuleColumn from "./ModuleColumn";

const modules = {
  Reporting: ["Summary View", "Drill-down", "PDF Export"],
  Planning: ["Timeline", "Milestones", "Dependencies"],
  Monitoring: ["Live Stats", "Error Alerts", "System Logs"],
  Notifications: ["Email Alerts", "Slack Integration", "Push"],
};

const lockConfig: Record<string, string[]> = {
  None: [],
  Basic: ["Monitoring"],
  Advanced: ["Monitoring", "Notifications"],
  Enterprise: ["Monitoring", "Notifications", "Reporting"],
};

const ModuleManager = () => {
  const [activeModules, setActiveModules] = useState<string[]>([]);
  const [expanded, setExpanded] = useState<Record<string, boolean>>({});
  const [mode, setMode] = useState("None");

  const locked = lockConfig[mode] ?? [];
  const allModules = Object.keys(modules);
  const available = allModules.filter((m) => !activeModules.includes(m));

  const toggleExpand = (title: string) =>
    setExpanded((prev) => ({ ...prev, [title]: !prev[title] }));

  const addToActive = (title: string) => {
    if (!activeModules.includes(title)) {
      setActiveModules((prev) => [...prev, title]);
    }
  };

  const removeFromActive = (title: string) => {
    if (!locked.includes(title)) {
      setActiveModules((prev) => prev.filter((m) => m !== title));
    }
  };

  // Automatically add locked modules when mode changes
  useEffect(() => {
    setActiveModules((prev) => {
      const withLocked = [...prev, ...locked.filter(m => !prev.includes(m))];

      return withLocked;
    });
  }, [mode]);

  return (
    <DndProvider backend={HTML5Backend}>
      <div className="max-w-6xl mx-auto p-6">
        <p className="text-gray-600">
              Select a mode to lock certain modules automatically. Drag and drop modules
              between Available and Active columns. Locked modules cannot be moved.
        </p>
        <hr className="my-4 border-gray-300" />
        <div className="flex gap-4">
            <ModuleColumn
            title="Available Modules"
            modules={available}
            onDrop={removeFromActive}
            lockedModules={[]}
            expanded={expanded}
            toggleExpand={toggleExpand}
            modulesData={modules}
            source="available"
            />
            <ModuleColumn
            title="Active Modules"
            modules={activeModules}
            onDrop={addToActive}
            lockedModules={locked}
            expanded={expanded}
            toggleExpand={toggleExpand}
            modulesData={modules}
            source="active"
            />
        </div>
        
        {/* Footer with Mode dropdown left and Download button right */}
        <div className="flex justify-between items-center mt-4 max-w-6xl mx-auto px-4">
        {/* Mode dropdown left */}
        <div className="flex items-center gap-2">
            <label className="font-semibold text-gray-700">Mode:</label>
            <select
            value={mode}
            onChange={(e) => setMode(e.target.value)}
            className="select select-bordered"
            >
            {Object.keys(lockConfig).map((m) => (
                <option key={m} value={m}>
                {m}
                </option>
            ))}
            </select>
        </div>

        {/* Download button right */}
        <button
            className="btn btn-primary"
            onClick={() => {
            // Your download logic here
            alert("Download started!");
            }}
        >
            Download Config
        </button>
        </div>
      </div>
    </DndProvider>
  );
};

export default ModuleManager;
