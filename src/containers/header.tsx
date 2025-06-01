"use client"
import { themeChange } from 'theme-change';
import React, { useEffect, useState } from 'react';
import Bars3Icon from '@heroicons/react/24/outline/Bars3Icon';
import MoonIcon from '@heroicons/react/24/outline/MoonIcon';
import SunIcon from '@heroicons/react/24/outline/SunIcon';
import { useAppSelector } from '../lib/hooks';

interface HeaderProps {
  contentRef : React.RefObject<HTMLElement>
}

function Header({contentRef}: HeaderProps): JSX.Element {

  const { pageTitle } = useAppSelector((state) => state.header);
  const [currentTheme, setCurrentTheme] = useState<string | null>(localStorage.getItem("theme"));

  // Scroll back to top on new page load
  useEffect(() => {
    if (contentRef.current) {
      (contentRef.current as HTMLDivElement).scroll({
        top: 0,
        behavior: "smooth"
      });
    }
  }, [pageTitle]);

  useEffect(() => {
    themeChange(false);
    if (currentTheme === null) {
      if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
        setCurrentTheme("dark");
      } else {
        setCurrentTheme("light");
      }
    }
  }, []);

  return (
    <div className="navbar sticky top-0 bg-base-100 z-10 shadow-md">
      {/* Menu toggle for mobile view or small screen */}
      <div className="flex-1">
        <label htmlFor="left-sidebar-drawer" className="btn btn-primary drawer-button lg:hidden">
          <Bars3Icon className="h-5 inline-block w-5" />
        </label>
        <h1 className="text-2xl font-semibold ml-2">{pageTitle}</h1>
      </div>

      <div className="flex-none">
        {/* Light and dark theme selection toggle */}
        <label className="swap">
          <input type="checkbox" />
          <SunIcon data-set-theme="light" data-act-class="ACTIVECLASS" className={`fill-current w-6 h-6 ${currentTheme === "dark" ? "swap-on" : "swap-off"}`} />
          <MoonIcon data-set-theme="dark" data-act-class="ACTIVECLASS" className={`fill-current w-6 h-6 ${currentTheme === "light" ? "swap-on" : "swap-off"}`} />
        </label>
      </div>
    </div>
  );
}

export default Header;
