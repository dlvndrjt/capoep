"use client"

import { useState } from "react"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ListingCardDialog } from "@/components/listing-card-dialog"
import { ReputationDisplay } from "@/components/reputation-display"
import { ListingSkeleton } from "@/components/listing-skeleton"
import { ListingType } from "@/types/listing"
import { EducationCategory } from "@/types/education"

// Mock data
const mockUserListings: ListingType[] = [
  {
    id: 1,
    title: "My Learning Journey in Web3",
    details: "Completed several courses and built DApps",
    creator: "0x1234...5678",
    proofs: ["https://example.com/cert1"],
    category: EducationCategory.STUDENT,
    minted: true,
    createdAt: Math.floor(Date.now() / 1000) - 86400,
    voteCount: { upvotes: 5, downvotes: 1 }
  },
  // Add more mock listings...
]

interface AccountTab {
  created: "created"
  voted: "voted"
  commented: "commented"
  minted: "minted"
}

export default function Account() {
  const [activeTab, setActiveTab] = useState<keyof AccountTab>("created")
  const [loading, setLoading] = useState(false)
  const [userAddress, setUserAddress] = useState("0x1234...5678") // Replace with wallet connection

  // Mock data for different tabs
  const tabData = {
    created: mockUserListings,
    voted: mockUserListings.slice(0, 1),
    commented: mockUserListings.slice(1, 2),
    minted: mockUserListings.filter(l => l.minted)
  }

  return (
    <div className="container mx-auto py-8 px-24">
      <div className="mb-8">
        <div className="flex items-center gap-4 mb-4">
          <h1 className="text-2xl font-bold">My Account</h1>
          <ReputationDisplay address={userAddress} />
        </div>
        <p className="text-sm text-muted-foreground">{userAddress}</p>
      </div>

      <Tabs defaultValue="created" className="space-y-4">
        <TabsList>
          <TabsTrigger value="created">Created Listings</TabsTrigger>
          <TabsTrigger value="voted">Voted Listings</TabsTrigger>
          <TabsTrigger value="commented">Commented Listings</TabsTrigger>
          <TabsTrigger value="minted">Minted NFTs</TabsTrigger>
        </TabsList>

        {Object.entries(tabData).map(([key, listings]) => (
          <TabsContent key={key} value={key} className="space-y-4">
            {loading ? (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {[...Array(3)].map((_, i) => (
                  <ListingSkeleton key={i} />
                ))}
              </div>
            ) : listings.length > 0 ? (
              <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                {listings.map((listing) => (
                  <ListingCardDialog key={listing.id} listing={listing} />
                ))}
              </div>
            ) : (
              <div className="text-center py-8 text-muted-foreground">
                No listings found
              </div>
            )}
          </TabsContent>
        ))}
      </Tabs>
    </div>
  )
} 