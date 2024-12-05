"use client";

import { Button } from "@/components/ui/button";
import { CreateListingDialog } from "@/components/create-listing-dialog";
import { useRouter } from "next/navigation";

export function Navbar() {
  const router = useRouter();

  const handleNavigation = (path: string) => {
    router.push(path);
  };

  return (
    <nav className="flex items-center justify-between bg-zinc-900 p-4 text-white">
      <Button
        variant="ghost"
        className="p-0 text-xl font-bold text-white hover:underline"
        onClick={() => handleNavigation("/home")}
      >
        CAPOEP
      </Button>
      <div className="flex items-center space-x-4">
        <CreateListingDialog />
        <Button
          variant="outline"
          className="border border-white text-black hover:bg-white hover:text-gray-800"
          onClick={() => handleNavigation("/account")}
        >
          Account
        </Button>
      </div>
    </nav>
  );
}
