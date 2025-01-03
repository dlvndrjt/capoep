"use client";

import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Button } from "@/components/ui/button";
import { ExternalLink, ThumbsUp, ThumbsDown } from "lucide-react";
import Link from "next/link";
import { ListingContent } from "./listing-content";
import { ReputationDisplay } from "./reputation-display";
import { CategoryLabels, EducationCategory } from "@/types/education";
import { Badge } from "@/components/ui/badge";

interface ListingType {
  id: number;
  title: string;
  details: string;
  creator: string;
  proofs: string[];
  category: EducationCategory;
  minted: boolean;
  createdAt: number;
  voteCount?: {
    upvotes: number;
    downvotes: number;
  };
}

export function ListingCardDialog({ listing }: { listing: ListingType }) {
  const [isOpen, setIsOpen] = useState(false);

  const handleOpenChange = (open: boolean) => {
    setIsOpen(open);
    if (open) {
      window.history.replaceState({}, "", `/listing/${listing.id}`);
    } else {
      window.history.replaceState({}, "", "/home");
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={handleOpenChange}>
      <DialogTrigger asChild>
        <Card className="group cursor-pointer hover:bg-accent">
          <CardHeader>
            <div className="flex items-start justify-between">
              <div>
                <CardTitle>{listing.title}</CardTitle>
                <div className="flex flex-wrap items-center gap-2 mt-1">
                  <Badge variant="secondary">
                    {CategoryLabels[listing.category]}
                  </Badge>
                  {listing.minted && (
                    <Badge variant="default">Minted</Badge>
                  )}
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
                  <CardDescription>
                    <div className="flex items-center gap-2">
                      <span>Created by: {listing.creator}</span>
                      <ReputationDisplay address={listing.creator} />
                    </div>
                  </CardDescription>
                </div>
              </div>
              <Link href={`/listing/${listing.id}`} target="_blank" passHref>
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
            <p className="line-clamp-2">{listing.details}</p>
            <div className="mt-2 text-sm text-muted-foreground">
              Created {new Date(listing.createdAt * 1000).toLocaleDateString()}
            </div>
          </CardContent>
        </Card>
      </DialogTrigger>

      <DialogContent className="h-[80vh] max-w-[600px] p-0 flex flex-col">
        <DialogHeader className="flex flex-row items-center justify-between p-6 shrink-0">
          <DialogTitle>{listing.title}</DialogTitle>
          <Link href={`/listing/${listing.id}`} target="_blank" passHref>
            <Button
              variant="ghost"
              size="sm"
              className="flex items-center gap-2 mr-4"
            >
              <ExternalLink className="h-4 w-4" />
              Open in new tab
            </Button>
          </Link>
        </DialogHeader>
        <ScrollArea className="min-h-0 flex-1 rounded-md border p-4">
          <ListingContent listing={listing} />
        </ScrollArea>
      </DialogContent>
    </Dialog>
  );
}
