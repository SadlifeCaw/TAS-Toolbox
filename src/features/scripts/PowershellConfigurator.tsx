import React, { useState, useEffect } from "react";

type Variable = {
  name: string;
  type: string;
  example?: string;
};

type Script = {
  topic: string;
  script: string;
  configPath: string;
  variables: Variable[] | Variable;
};

type Props = {
  scripts: Script[];
};

const PowershellConfigurator: React.FC<Props> = ({ scripts }) => {
  const [selectedScript, setSelectedScript] = useState<Script | null>(null);
  const [values, setValues] = useState<Record<string, string>>({});
  const [collapsedTopics, setCollapsedTopics] = useState<Record<string, boolean>>({});

  const groupedScripts = scripts.reduce<Record<string, Script[]>>((acc, script) => {
    if (!acc[script.topic]) acc[script.topic] = [];
    acc[script.topic].push(script);
    return acc;
  }, {});

  useEffect(() => {
    const initialCollapseState: Record<string, boolean> = {};
    Object.keys(groupedScripts).forEach((topic) => {
      initialCollapseState[topic] = true;
    });
    setCollapsedTopics(initialCollapseState);
  }, [scripts]);

  const handleSelect = (script: Script) => {
    setSelectedScript(script);
    const initialValues: Record<string, string> = {};
    const vars = Array.isArray(script.variables)
      ? script.variables
      : [script.variables];
    vars.forEach((v) => {
      initialValues[v.name] = "";
    });
    setValues(initialValues);
  };

  const handleChange = (name: string, value: string) => {
    setValues((prev) => ({ ...prev, [name]: value }));
  };

  const handleDownload = async () => {
    if (!selectedScript) return;

    try {
      const response = await fetch("/api/powershellfiles", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          configPath: selectedScript.configPath,
          values,
          script: selectedScript.script,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        alert(`Error: ${errorData.error || "Failed to download script"}`);
        return;
      }

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;

      // Filename from Content-Disposition header fallback to script name
      const disposition = response.headers.get("Content-Disposition");
      let filename = `${selectedScript.script.replace(/\s+/g, "_")}.zip`;
      if (disposition) {
        const match = disposition.match(/filename="(.+)"/);
        if (match && match[1]) {
          filename = match[1];
        }
      }

      a.download = filename;
      document.body.appendChild(a);
      a.click();
      a.remove();
      window.URL.revokeObjectURL(url);
    } catch (error) {
      alert("Error downloading the script");
      console.error(error);
    }
  };


  const toggleTopic = (topic: string) => {
    setCollapsedTopics((prev) => ({
      ...prev,
      [topic]: !prev[topic],
    }));
  };

  return (
    <div className="flex gap-6 p-4 border rounded-lg shadow-md bg-white">
      <div className="w-1/3 border-r pr-4 max-h-[500px] overflow-y-auto">
        {Object.entries(groupedScripts).map(([topic, scripts]) => (
          <div key={topic} className="mb-4">
            <button
              onClick={() => toggleTopic(topic)}
              className="w-full flex justify-between items-center text-md font-bold text-gray-800 mb-1 p-2 rounded hover:bg-gray-100"
            >
              <span>{topic}</span>
              <span>{collapsedTopics[topic] ? "▶" : "▼"}</span>
            </button>
            {!collapsedTopics[topic] && (
              <ul className="space-y-1 pl-4">
                {scripts.map((script, index) => (
                  <li key={index}>
                    <button
                      className={`w-full text-left p-2 rounded ${
                        selectedScript?.script === script.script
                          ? "bg-blue-100 font-semibold"
                          : "hover:bg-gray-100"
                      }`}
                      onClick={() => handleSelect(script)}
                    >
                      {script.script}
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        ))}
      </div>

      <div className="w-2/3 pl-4">
        {selectedScript ? (
          <>
            <h2 className="text-lg font-semibold mb-2">
              {selectedScript.script}
            </h2>
            <div className="space-y-4">
              {(Array.isArray(selectedScript.variables)
                ? selectedScript.variables
                : [selectedScript.variables]
              ).map((v) => (
                <div key={v.name}>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    {v.name}
                  </label>
                  <input
                    type="text"
                    className="w-full border rounded px-3 py-2"
                    value={values[v.name] || ""}
                    onChange={(e) => handleChange(v.name, e.target.value)}
                    placeholder={v.example || ""}
                  />
                </div>
              ))}
            </div>

            <button
              className="mt-6 px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
              onClick={handleDownload}
            >
              Download PowerShell Script
            </button>
          </>
        ) : (
          <p className="text-gray-500">Select a script to edit variables.</p>
        )}
      </div>
    </div>
  );
};

export default PowershellConfigurator;
