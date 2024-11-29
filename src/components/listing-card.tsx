"use client";

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { ThumbsUp, ThumbsDown } from "lucide-react";
import { useState } from "react";
import { CommentsSection } from "./comments-section";
import { Textarea } from "./ui/textarea";

interface ListingCardProps {
  id: number;
  title: string;
  details: string;
  creator: string;
  proofs: string[];
}

export function ListingCard({
  id,
  title,
  details,
  creator,
  proofs,
}: ListingCardProps) {
  const [isVoting, setIsVoting] = useState(false);
  const [voteComment, setVoteComment] = useState("");

  const handleVote = async (thumbsUp: boolean) => {
    if (!voteComment) {
      setIsVoting(true);
      return;
    }

    try {
      // TODO: Implement contract interaction for voting
      console.log("Voting:", { listingId: id, thumbsUp, comment: voteComment });
      setVoteComment("");
      setIsVoting(false);
    } catch (error) {
      console.error("Error voting:", error);
    }
  };

  return (
    <Dialog>
      <DialogTrigger asChild>
        <Card className="cursor-pointer hover:bg-accent">
          <CardHeader>
            <CardTitle>{title}</CardTitle>
            <CardDescription>Created by: {creator}</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="line-clamp-2">{details}</p>
          </CardContent>
        </Card>
      </DialogTrigger>
      <DialogContent className="flex max-h-[80vh] max-w-[600px] flex-col">
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
        </DialogHeader>
        <div className="space-y-4 overflow-y-auto pr-6">
          <p className="text-sm text-muted-foreground">Created by: {creator}</p>
          <div>
            <h4 className="mb-2 font-medium">Details:</h4>
            <p>{details}</p>
          </div>
          <div>
            <h4 className="mb-2 font-medium">Proofs:</h4>
            <ul className="list-disc pl-4">
              {proofs.map((proof, index) => (
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
            <CommentsSection listingId={id} />
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
