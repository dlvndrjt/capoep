"use client"

import { Button } from "@/components/ui/button"
import Link from "next/link"
import { CreateListingDialog } from "@/components/create-listing-dialog"

export function Navbar() {
  return (
    <nav className="flex justify-between items-center p-4 bg-gray-800 text-white">
      <Link href="/home" className="text-xl font-bold hover:underline">
        CAPOL
      </Link>
      <div className="flex items-center space-x-4">
        <CreateListingDialog />
        <Link href="/account">
          <Button variant="outline" className="border border-white text-black hover:bg-white hover:text-gray-800">
            Account
          </Button>
        </Link>
      </div>
    </nav>
  )
} 