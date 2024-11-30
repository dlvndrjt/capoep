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
import { ThumbsUp, ThumbsDown, ExternalLink } from "lucide-react";
import { useState, useEffect } from "react";
import { CommentsSection } from "./comments-section";
import { Textarea } from "./ui/textarea";
import Link from "next/link";
import { useRouter, usePathname } from "next/navigation";

interface ListingCardProps {
  id: number;
  title: string;
  details: string;
  creator: string;
  proofs: string[];
  isStandalone?: boolean;
}

export function ListingCard({
  id,
  title,
  details,
  creator,
  proofs,
  isStandalone = false,
}: ListingCardProps) {
  const [isVoting, setIsVoting] = useState(false);
  const [voteComment, setVoteComment] = useState("");
  const [isOpen, setIsOpen] = useState(false);
  const router = useRouter();
  const pathname = usePathname();

  // Update URL when dialog opens/closes
  useEffect(() => {
    if (isOpen && !isStandalone) {
      router.replace(`/listing/${id}`, { scroll: false });
    } else if (!isOpen && !isStandalone && pathname.startsWith("/listing/")) {
      router.replace("/home", { scroll: false });
    }
  }, [isOpen, id, isStandalone, router, pathname]);

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

  const ListingContent = () => (
    <>
      <div className="space-y-4 overflow-y-auto pr-6">
        <div className="flex items-center justify-between">
          <p className="text-sm text-muted-foreground">Created by: {creator}</p>
          {!isStandalone && (
            <Link href={`/listing/${id}`} target="_blank" passHref>
              <Button variant="ghost" size="sm">
                <ExternalLink className="mr-2 h-4 w-4" />
                Open in new tab
              </Button>
            </Link>
          )}
        </div>
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
    </>
  );

  if (isStandalone) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>{title}</CardTitle>
          <CardDescription>Created by: {creator}</CardDescription>
        </CardHeader>
        <CardContent>
          <ListingContent />
        </CardContent>
      </Card>
    );
  }

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Card className="group cursor-pointer hover:bg-accent">
          <CardHeader>
            <div className="flex items-start justify-between">
              <div>
                <CardTitle>{title}</CardTitle>
                <CardDescription>Created by: {creator}</CardDescription>
              </div>
              <Link href={`/listing/${id}`} target="_blank" passHref>
                <Button
                  variant="ghost"
                  size="sm"
                  className="opacity-0 transition-opacity group-hover:opacity-100"
                  onClick={(e) => e.stopPropagation()}
                >
                  <ExternalLink className="h-4 w-4" />
                </Button>
              </Link>
            </div>
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
        <ListingContent />
      </DialogContent>
    </Dialog>
  );
}
