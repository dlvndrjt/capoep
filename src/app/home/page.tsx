"use client"

import { ListingCardDialog } from "@/components/listing-card-dialog"

const mockListings = [
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

export default function Home() {
  return (
    <div className="container mx-auto py-8">
      <h1 className="text-2xl font-bold mb-6">Learning Proofs</h1>
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {mockListings.map((listing) => (
          <ListingCardDialog key={listing.id} listing={listing} />
        ))}
      </div>
    </div>
  )
}
