"use client"

import { Button } from "@/components/ui/button"
import Link from "next/link"
import { CreateListingDialog } from "@/components/create-listing-dialog"
import { useRouter } from "next/navigation"

export function Navbar() {
  const router = useRouter()

  const handleNavigation = (path: string) => {
    router.push(path)
  }

  return (
    <nav className="flex justify-between items-center p-4 bg-gray-800 text-white">
      <Button
        variant="ghost"
        className="text-xl font-bold hover:underline p-0 text-white"
        onClick={() => handleNavigation("/home")}
      >
        CAPOL
      </Button>
      <div className="flex items-center space-x-4">
        <CreateListingDialog />
        <Button
          variant="outline"
          className="border border-white text-white hover:bg-white hover:text-gray-800"
          onClick={() => handleNavigation("/account")}
        >
          Account
        </Button>
      </div>
    </nav>
  )
} 