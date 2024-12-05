import { EducationCategory } from "./education"

export interface ListingType {
  id: number
  title: string
  details: string
  creator: string
  proofs: string[]
  category: EducationCategory
  minted: boolean
  createdAt: number
  voteCount?: {
    upvotes: number
    downvotes: number
  }
} 