"use client"

import { Button } from "@/components/ui/button"
import { ThumbsUp, ThumbsDown } from "lucide-react"
import { useState } from "react"
import { Textarea } from "./ui/textarea"
import { CommentsSection } from "./comments-section"

interface ListingType {
  id: number
  title: string
  details: string
  creator: string
  proofs: string[]
}

export function ListingContent({ listing }: { listing: ListingType }) {
  const [isVoting, setIsVoting] = useState(false)
  const [voteComment, setVoteComment] = useState("")

  const handleVote = async (thumbsUp: boolean) => {
    if (!voteComment) {
      setIsVoting(true)
      return
    }

    try {
      // TODO: Implement contract interaction for voting
      console.log("Voting:", { listingId: listing.id, thumbsUp, comment: voteComment })
      setVoteComment("")
      setIsVoting(false)
    } catch (error) {
      console.error("Error voting:", error)
    }
  }

  return (
    <div className="space-y-4">
      <p className="text-sm text-muted-foreground">Created by: {listing.creator}</p>
      <div>
        <h4 className="mb-2 font-medium">Details:</h4>
        <p>{listing.details}</p>
      </div>
      <div>
        <h4 className="mb-2 font-medium">Proofs:</h4>
        <ul className="list-disc pl-4">
          {listing.proofs.map((proof, index) => (
            <li key={index}>
              <a
                href={proof}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-500 hover:underline"
              >
                {proof}
              </a>
            </li>
          ))}
        </ul>
      </div>

      <div className="space-y-4">
        <div className="flex gap-4">
          <Button
            variant="outline"
            size="sm"
            onClick={() => handleVote(true)}
            className="flex items-center gap-2"
          >
            <ThumbsUp className="h-4 w-4" /> Attest
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => handleVote(false)}
            className="flex items-center gap-2"
          >
            <ThumbsDown className="h-4 w-4" /> Refute
          </Button>
        </div>

        {isVoting && (
          <div className="space-y-2">
            <Textarea
              placeholder="Add a comment for your vote..."
              value={voteComment}
              onChange={(e) => setVoteComment(e.target.value)}
            />
            <div className="flex gap-2">
              <Button size="sm" onClick={() => setIsVoting(false)}>
                Cancel
              </Button>
              <Button size="sm" onClick={() => handleVote(true)}>
                Submit Vote
              </Button>
            </div>
          </div>
        )}
      </div>

      <div className="border-t pt-4">
        <CommentsSection listingId={listing.id} />
      </div>
    </div>
  )
} 