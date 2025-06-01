import React, { useState, useEffect } from "react";
import { Prism as SyntaxHighlighter } from "react-syntax-highlighter";
import { tomorrow } from "react-syntax-highlighter/dist/esm/styles/prism";

type Script = {
  topic: string;
  script: string;
  filePath: string;
};

type Props = {
  scripts: Script[];
};

const SqlConfigurator: React.FC<Props> = ({ scripts }) => {
  const [selectedScript, setSelectedScript] = useState<Script | null>(null);
  const [scriptContent, setScriptContent] = useState<string>("");

  const [collapsedTopics, setCollapsedTopics] = useState<Record<string, boolean>>({});

  // Group scripts by topic
  const groupedScripts = scripts.reduce<Record<string, Script[]>>((acc, script) => {
    if (!acc[script.topic]) acc[script.topic] = [];
    acc[script.topic].push(script);
    return acc;
  }, {});

  useEffect(() => {
    // Initially collapse all topics
    const initialCollapseState: Record<string, boolean> = {};
    Object.keys(groupedScripts).forEach((topic) => {
      initialCollapseState[topic] = true;
    });
    setCollapsedTopics(initialCollapseState);
  }, [scripts]);

  useEffect(() => {
    if (!selectedScript) {
      setScriptContent("");
      return;
    }

    fetch(`/api/sqlfiles?path=${encodeURIComponent(selectedScript.filePath)}`)
      .then(res => res.blob())
      .then(blob => {
        return blob.text(); // this reads as UTF-8 by default
      })
      .then(text => setScriptContent(text))
      .catch(() => setScriptContent("-- Failed to load SQL script content --"));
  }, [selectedScript]);


  const toggleTopic = (topic: string) => {
    setCollapsedTopics((prev) => ({
      ...prev,
      [topic]: !prev[topic],
    }));
  };

  const [copied, setCopied] = useState(false);

   const copyToClipboard = async () => {
    if (!scriptContent || !selectedScript) return;
  
    try {
      await navigator.clipboard.writeText(scriptContent);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
  
      // Send copy event to API
      await fetch("/api/download-history", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user: "currentUser",          // Replace with your actual user info
          script: selectedScript.script,
          action: "copy",
          timestamp: new Date().toISOString(),
          status: "Success",
        }),
      });
    } catch (err) {
      console.error("Copy failed or logging failed", err);
  
      // Optionally, log a failed status to your API too
      await fetch("/api/download-history", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user: "currentUser",
          customer: "currentCustomer",
          script: selectedScript.script,
          action: "copy",
          timestamp: new Date().toISOString(),
          status: "Failed",
        }),
      });
    }
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
                        selectedScript?.filePath === script.filePath
                          ? "bg-blue-100 font-semibold"
                          : "hover:bg-gray-100"
                      }`}
                      onClick={() => setSelectedScript(script)}
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

      <div className="w-2/3 pl-4 max-h-[500px] overflow-auto relative">
        {selectedScript ? (
          <>
            <div className="flex justify-between items-center mb-2">
              <h2 className="text-lg font-semibold">{selectedScript.script}</h2>
              <button
                onClick={copyToClipboard}
                className="text-sm bg-blue-500 text-white px-3 py-1 rounded hover:bg-blue-600 transition"
                title="Copy SQL to clipboard"
              >
                {copied ? "Copied!" : "Copy"}
              </button>
            </div>
            <SyntaxHighlighter
              language="sql"
              style={tomorrow}
              className="max-h-[450px] overflow-auto rounded"
              wrapLongLines={true}
            >
              {scriptContent || "Loading..."}
            </SyntaxHighlighter>
          </>
        ) : (
          <p className="text-gray-500">Select a script to view its SQL code.</p>
        )}
      </div>
    </div>
  );
};

export default SqlConfigurator;
