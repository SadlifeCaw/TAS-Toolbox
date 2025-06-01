"use client";

import React from 'react';
import TitleCard from '../../components/cards/title-card';
import OrdningSettings from './OrdningSettings';
import DownloadHistory from './DownloadHistory';
import DashboardStats from './DashboardStats';

import UserGroupIcon from '@heroicons/react/24/outline/UserGroupIcon';
import UsersIcon from '@heroicons/react/24/outline/UsersIcon';
import CircleStackIcon from '@heroicons/react/24/outline/CircleStackIcon';
import CreditCardIcon from '@heroicons/react/24/outline/CreditCardIcon';
import {
  ArrowDownTrayIcon,
  PlusIcon,
  XMarkIcon,
  DocumentTextIcon,
  ClipboardDocumentIcon,
} from "@heroicons/react/24/outline";

const statsData = [
    { title: "New Users", value: "34.7k", icon: <UserGroupIcon className='w-8 h-8' />, description: "↗︎ 2300 (22%)" },
    { title: "Total Sales", value: "$34,545", icon: <CreditCardIcon className='w-8 h-8' />, description: "Current month" },
    { title: "Pending Leads", value: "450", icon: <CircleStackIcon className='w-8 h-8' />, description: "50 in hot leads" },
    { title: "Active Users", value: "5.6k", icon: <UsersIcon className='w-8 h-8' />, description: "↙ 300 (18%)" },
];

const Dashboard: React.FC = () => {
    return (
        <>  
            <div className="flex flex-wrap justify-center gap-4 p-4">
                <DashboardStats
                title="Total Downloads"
                icon={<ArrowDownTrayIcon className="w-10 h-10" />}
                value={15}
                description="↗︎ +12% from last month"
                colorIndex={1}
                />
                <DashboardStats
                title="Active Users"
                icon={<UserGroupIcon className="w-10 h-10" />}
                value={1}
                description="↙ -0% from last week"
                colorIndex={3}
                />
                <DashboardStats
                title="New Scripts Added"
                icon={<PlusIcon className="w-10 h-10" />}
                value={32}
                description="Stable"
                colorIndex={0}
                />
                <DashboardStats
                title="Failed Downloads"
                icon={<XMarkIcon className="w-10 h-10" />}
                value={0}
                description="↗︎ Decreased errors"
                colorIndex={1}
                />
                <DashboardStats
                title="Avg. Script Size"
                icon={<DocumentTextIcon className="w-10 h-10" />}
                value="1.2 MB"
                description="↙ Slightly down"
                colorIndex={3}
                />
                <DashboardStats
                title="Last Copy Action"
                icon={<ClipboardDocumentIcon className="w-10 h-10" />}
                value="10 mins ago"
                description="↗︎ More copies today"
                colorIndex={1}
                />
            </div>
            <TitleCard title="Download History">
                <DownloadHistory />
            </TitleCard>
        </>
    );
};

export default Dashboard;
