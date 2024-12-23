"use client"

import { Button } from "@/components/ui/button"
import { ThumbsUp, ThumbsDown } from "lucide-react"
import { useState } from "react"
import { Textarea } from "./ui/textarea"
import { CommentsSection } from "./comments-section"
import { Badge } from "@/components/ui/badge"
import { CategoryLabels } from "@/types/education"
import { ListingType } from "@/types/listing"
import { ReputationDisplay } from "./reputation-display"

export function ListingContent({ listing }: { listing: ListingType }) {
  const [isVoting, setIsVoting] = useState(false)
  const [voteComment, setVoteComment] = useState("")
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleVote = async (thumbsUp: boolean) => {
    if (!voteComment) {
      setIsVoting(true)
      return
    }

    try {
      setIsSubmitting(true)
      // TODO: Implement contract interaction for voting
      console.log("Voting:", { listingId: listing.id, thumbsUp, comment: voteComment })
      setVoteComment("")
      setIsVoting(false)
    } catch (error) {
      console.error("Error voting:", error)
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleMint = async () => {
    try {
      setIsSubmitting(true)
      // TODO: Implement contract interaction for minting
      console.log("Minting listing:", listing.id)
    } catch (error) {
      console.error("Error minting:", error)
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-2">
        <Badge variant="secondary">
          {CategoryLabels[listing.category]}
        </Badge>
        <Badge variant={listing.minted ? "default" : "secondary"}>
          {listing.minted ? "Minted" : "Not Minted"}
        </Badge>
        <div className="flex items-center gap-2">
          <Badge variant="outline" className="flex items-center gap-1">
            <ThumbsUp className="h-3 w-3" />
            {listing.voteCount?.upvotes || 0}
          </Badge>
          <Badge variant="outline" className="flex items-center gap-1">
            <ThumbsDown className="h-3 w-3" />
            {listing.voteCount?.downvotes || 0}
          </Badge>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <span className="text-sm text-muted-foreground">Created by: {listing.creator}</span>
        <ReputationDisplay address={listing.creator} />
        <span className="text-sm text-muted-foreground">•</span>
        <span className="text-sm text-muted-foreground">
          {new Date(listing.createdAt * 1000).toLocaleDateString()}
        </span>
      </div>

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
            disabled={isSubmitting}
          >
            <ThumbsUp className="h-4 w-4" /> Attest
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => handleVote(false)}
            className="flex items-center gap-2"
            disabled={isSubmitting}
          >
            <ThumbsDown className="h-4 w-4" /> Refute
          </Button>
          {!listing.minted && (
            <Button
              variant="default"
              size="sm"
              onClick={handleMint}
              className="ml-auto"
              disabled={isSubmitting}
            >
              Mint NFT
            </Button>
          )}
        </div>

        {isVoting && (
          <div className="space-y-2">
            <Textarea
              placeholder="Add a comment for your vote..."
              value={voteComment}
              onChange={(e) => setVoteComment(e.target.value)}
              disabled={isSubmitting}
            />
            <div className="flex gap-2">
              <Button 
                size="sm" 
                onClick={() => setIsVoting(false)}
                disabled={isSubmitting}
              >
                Cancel
              </Button>
              <Button 
                size="sm" 
                onClick={() => handleVote(true)}
                disabled={isSubmitting}
              >
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