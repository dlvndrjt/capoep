"use client"

import { ListingCardDialog } from "./listing-card-dialog"
import { ListingSkeleton } from "./listing-skeleton"
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
  loading?: boolean
}

export function ListingGrid({ listings, loading = false }: ListingGridProps) {
  if (loading) {
    return (
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {[...Array(6)].map((_, i) => (
          <ListingSkeleton key={i} />
        ))}
      </div>
    )
  }

  if (listings.length === 0) {
    return (
      <div className="text-center py-12">
        <p className="text-lg text-muted-foreground">No listings found</p>
      </div>
    )
  }

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {listings.map((listing) => (
        <ListingCardDialog key={listing.id} listing={listing} />
      ))}
    </div>
  )
} 