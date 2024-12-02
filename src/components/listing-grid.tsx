"use client"

import { ListingCardDialog } from "./listing-card-dialog"
import { EducationCategory } from "@/types/education"

interface Listing {
  id: number
  title: string
  details: string
  creator: string
  proofs: string[]
  category: EducationCategory
}

interface ListingGridProps {
  listings: Listing[]
}

export function ListingGrid({ listings }: ListingGridProps) {
  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {listings.map((listing) => (
        <ListingCardDialog key={listing.id} listing={listing} />
      ))}
    </div>
  )
} 