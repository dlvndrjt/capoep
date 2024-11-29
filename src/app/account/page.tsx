"use client"
import { useState } from "react"
import { ListingCard } from "@/components/listing-card"

// Temporary mock data for user's listings and comments
const mockUserListings = [
  {
    id: 1,
    title: "Completed Full Stack Development Course",
    details: "I have completed a comprehensive full stack development course covering React, Node.js, and MongoDB.",
    creator: "0x1234...5678",
    proofs: ["https://example.com/certificate1", "https://example.com/project1"],
  },
  {
    id: 2,
    title: "Mastered Solidity Smart Contracts",
    details: "Completed advanced Solidity programming course and deployed multiple smart contracts.",
    creator: "0x8765...4321",
    proofs: ["https://example.com/certificate2", "https://github.com/myprojects"],
  },
]

export default function Account() {
  const [userListings] = useState(mockUserListings)

  return (
    <div className="container mx-auto py-8">
      <h1 className="text-2xl font-bold mb-6">My Account</h1>
      <h2 className="text-xl font-semibold mb-4">Created Listings</h2>
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {userListings.map((listing) => (
          <ListingCard key={listing.id} {...listing} />
        ))}
      </div>
    </div>
  )
} 