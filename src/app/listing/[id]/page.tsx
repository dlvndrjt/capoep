"use client"

import { useParams } from "next/navigation"
import { ListingContent } from "@/components/listing-content"
import { Card, CardHeader, CardTitle, CardDescription } from "@/components/ui/card"

// This will be replaced with actual data fetching
const getListing = (id: string) => {
  return {
    id: parseInt(id),
    title: "Completed Full Stack Development Course",
    details: "I have completed a comprehensive full stack development course covering React, Node.js, and MongoDB.",
    creator: "0x1234...5678",
    proofs: ["https://example.com/certificate1", "https://example.com/project1"],
  }
}

export default function ListingPage() {
  const params = useParams()
  const listingId = params.id as string
  const listing = getListing(listingId)

  return (
    <div className="container mx-auto py-8">
      <Card>
        <CardHeader>
          <CardTitle>{listing.title}</CardTitle>
          <CardDescription>Created by: {listing.creator}</CardDescription>
        </CardHeader>
        <div className="p-6">
          <ListingContent listing={listing} />
        </div>
      </Card>
    </div>
  )
} 