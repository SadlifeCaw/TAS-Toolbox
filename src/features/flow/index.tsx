"use client";

import React from "react";
import PlainCard from "@/components/cards/plain-card";
import TitleCard from "@/components/cards/title-card";
import ModuleManager from "./ModuleManager";
import OrdningSettings from '../dashboard/OrdningSettings';

const Flow: React.FC = () => {
  return (
    <>
    <TitleCard title="Konfigurationer">
        <OrdningSettings />
    </TitleCard>

    <TitleCard title="Module Manager">
      <ModuleManager />
    </TitleCard>
    </>
  );
};

export default Flow;
