"use client";
import React, { useState, useEffect } from "react";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";

type DownloadHistoryRecord = {
  timestamp: string;
  user: string;
  script: string;
  status: "Success" | "Failed";
};

const DownloadHistory: React.FC = () => {
  const [downloads, setDownloads] = useState<DownloadHistoryRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [selectedDate, setSelectedDate] = useState<Date | null>(new Date());

  useEffect(() => {
    fetch("/api/download-history")
      .then((res) => {
        if (!res.ok) throw new Error("Failed to fetch download history");
        return res.json();
      })
      .then((data: DownloadHistoryRecord[]) => {
        const sortedData = data.sort(
          (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
        );
        setDownloads(sortedData);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message || "Unknown error");
        setLoading(false);
      });
  }, []);


  const getStatusBadge = (status: "Success" | "Failed") => {
    if (status === "Success") return <div className="badge badge-success">{status}</div>;
    return <div className="badge badge-error">{status}</div>;
  };

  const formatDate = (isoString: string) => {
    const date = new Date(isoString);
    return date.toLocaleString(undefined, {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  const filteredDownloads = selectedDate
    ? downloads.filter((record) => {
        const recordDate = new Date(record.timestamp);
        return (
          recordDate.getFullYear() === selectedDate.getFullYear() &&
          recordDate.getMonth() === selectedDate.getMonth() &&
          recordDate.getDate() === selectedDate.getDate()
        );
      })
    : downloads;

  if (loading) return <p>Loading download history...</p>;
  if (error) return <p className="text-red-600">Error: {error}</p>;

  return (
    <div>
      <div className="mb-4">
        <label className="mr-2 font-semibold">Filter by Date:</label>
        <DatePicker
          selected={selectedDate}
          onChange={(date) => setSelectedDate(date)}
          isClearable
          placeholderText="Select a date"
          dateFormat="dd MMM yyyy"
        />
      </div>

      <div className="overflow-x-auto w-full">
        <table className="table w-full">
          <thead>
            <tr>
              <th>Download Date</th>
              <th>User</th>
              <th>Script</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {filteredDownloads.map((record, index) => (
              <tr key={index}>
                <td>{formatDate(record.timestamp)}</td>
                <td>{record.user}</td>
                <td>{record.script}</td>
                <td>{getStatusBadge(record.status)}</td>
              </tr>
            ))}
          </tbody>
        </table>

        {filteredDownloads.length === 0 && <p className="mt-4">No downloads found for selected date.</p>}
      </div>
    </div>
  );
};

export default DownloadHistory;
