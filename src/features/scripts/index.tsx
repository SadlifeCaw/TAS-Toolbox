"use client";

import React from "react";
import TitleCard from "@/components/cards/title-card";
import OrdningSettings from '../dashboard/OrdningSettings';
import PowershellConfigurator from "./PowershellConfigurator";
import powershellScriptsJson from '../../helper/script-powershell-map.json'
import sqlScriptsJson from '../../helper/script-sql-map.json'
import CollapsibleCard from "@/components/cards/collapsible-card";
import SqlConfigurator from "./SqlConfigurator";

const Scripts: React.FC = () => {
  return (
    <>
    <CollapsibleCard title="Powershell Scripts">
      <PowershellConfigurator scripts={powershellScriptsJson}/>
    </CollapsibleCard>
    <CollapsibleCard title="SQL Scripts">
      <SqlConfigurator scripts={sqlScriptsJson}/>
    </CollapsibleCard>
    </>
  );
};

export default Scripts;
