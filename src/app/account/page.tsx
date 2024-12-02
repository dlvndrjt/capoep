"use client"
import { useState } from "react"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { ListingCard } from "@/components/listing-card"
import { ReputationDisplay } from "@/components/reputation-display"

interface AccountTab {
  created: "created"
  voted: "voted"
  commented: "commented"
  minted: "minted"
}

export default function Account() {
  const [activeTab, setActiveTab] = useState<keyof AccountTab>("created")

  return (
    <div className="container mx-auto py-8">
      <div className="mb-8">
        <div className="flex items-center gap-4 mb-4">
          <h1 className="text-2xl font-bold">My Account</h1>
          <ReputationDisplay address={"user_address"} />
        </div>
        <p className="text-sm text-muted-foreground">{"user_address"}</p>
      </div>

      <Tabs defaultValue="created" className="space-y-4">
        <TabsList>
          <TabsTrigger value="created">Created Listings</TabsTrigger>
          <TabsTrigger value="voted">Voted Listings</TabsTrigger>
          <TabsTrigger value="commented">Commented Listings</TabsTrigger>
          <TabsTrigger value="minted">Minted NFTs</TabsTrigger>
        </TabsList>

        <TabsContent value="created" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {/* Show listings created by user */}
          </div>
        </TabsContent>

        <TabsContent value="voted" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {/* Show listings user has voted on */}
          </div>
        </TabsContent>

        <TabsContent value="commented" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {/* Show listings user has commented on */}
          </div>
        </TabsContent>

        <TabsContent value="minted" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {/* Show NFTs minted by user */}
          </div>
        </TabsContent>
      </Tabs>
    </div>
  )
} 