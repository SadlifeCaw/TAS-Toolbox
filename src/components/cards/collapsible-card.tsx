import React, { useState, ReactNode } from "react";
import Subtitle from "../typography/subtitle";
import { ChevronDownIcon, ChevronUpIcon } from "@heroicons/react/24/outline";

interface CollapsibleCardProps {
    title: string;
    children: ReactNode;
    topMargin?: string;
}

function CollapsibleCard({ title, children, topMargin }: CollapsibleCardProps) {
    const [isOpen, setIsOpen] = useState(true);

    const toggleOpen = () => setIsOpen(!isOpen);

    return (
        <div className={"card w-full p-6 bg-base-100 shadow-xl " + (topMargin || "mt-6")}>

            {/* Title and Toggle Button */}
            <div className="flex justify-between items-center">
                <Subtitle>{title}</Subtitle>
                <button onClick={toggleOpen} className="btn btn-ghost btn-sm">
                    {isOpen ? (
                        <ChevronUpIcon className="w-5 h-5" />
                    ) : (
                        <ChevronDownIcon className="w-5 h-5" />
                    )}
                </button>
            </div>

            <div className="divider mt-2" />

            {/* Collapsible Content */}
            {isOpen && (
                <div className='h-full w-full pb-6 bg-base-100'>
                    {children}
                </div>
            )}
        </div>
    );
}

export default CollapsibleCard;
