"use client";

import { useState } from "react";
import { EducationCategory } from "@/types/education";
import { CategoryFilter } from "@/components/category-filter";
import { ListingGrid } from "@/components/listing-grid";

const mockListings = [
  {
    id: 1,
    title: "Completed Full Stack Development Course",
    details:
      "I have completed a comprehensive full stack development course covering React, Node.js, and MongoDB.",
    creator: "0x1234...5678",
    proofs: [
      "https://example.com/certificate1",
      "https://example.com/project1",
    ],
    category: EducationCategory.STUDENT,
  },
  {
    id: 2,
    title: "Mastered Solidity Smart Contracts",
    details:
      "Completed advanced Solidity programming course and deployed multiple smart contracts.",
    creator: "0x8765...4321",
    proofs: [
      "https://example.com/certificate2",
      "https://github.com/myprojects",
    ],
    category: EducationCategory.EDUCATOR,
  },
];

export default function Home() {
  const [selectedCategory, setSelectedCategory] =
    useState<EducationCategory | null>(null);

  const filteredListings =
    selectedCategory !== null
      ? mockListings.filter((listing) => listing.category === selectedCategory)
      : mockListings;

  return (
    <div className="container mx-auto py-8">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">
          Community Attested Proof of Education Protocol
        </h1>
        <CategoryFilter
          selectedCategory={selectedCategory}
          onCategoryChange={setSelectedCategory}
        />
      </div>
      <ListingGrid listings={filteredListings} />
    </div>
  );
}
