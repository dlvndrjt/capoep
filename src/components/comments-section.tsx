"use client"

import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { useState } from "react"
import { Reply, ArrowBigUp, ArrowBigDown  } from "lucide-react"
import { ReputationDisplay } from "./reputation-display"

interface Comment {
  id: string
  commenter: string
  content: string
  votes: number
  timestamp: string
  replies?: Comment[]
}

interface VoteComment {
  voter: string
  thumbsUp: boolean
  comment: string
  timestamp: string
}

// Mock data for development
const mockComments: Comment[] = [
  {
    id: "1",
    commenter: "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
    content: "This is really impressive work! The implementation shows great understanding of the concepts.",
    votes: 15,
    timestamp: "2 hours ago",
    replies: [
      {
        id: "1-1",
        commenter: "0x123f35Cc6634C0532925a3b844Bc454e4438f123",
        content: "Agreed! Especially the smart contract architecture.",
        votes: 5,
        timestamp: "1 hour ago"
      }
    ]
  },
  {
    id: "2",
    commenter: "0x952d35Cc6634C0532925a3b844Bc454e4438f785",
    content: "Could you explain more about how you handled the async operations?",
    votes: 8,
    timestamp: "3 hours ago"
  }
]

const mockVoteComments: VoteComment[] = [
  {
    voter: "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
    thumbsUp: true,
    comment: "Great documentation and clean code!",
    timestamp: "1 hour ago"
  },
  {
    voter: "0x952d35Cc6634C0532925a3b844Bc454e4438f785",
    thumbsUp: false,
    comment: "Needs more test coverage",
    timestamp: "2 hours ago"
  }
]

interface CommentsSectionProps {
  listingId: number
  comments?: Comment[]
  voteComments?: VoteComment[]
}

function CommentComponent({ comment }: { comment: Comment }) {
  const [isReplying, setIsReplying] = useState(false)
  const [replyContent, setReplyContent] = useState("")

  const handleVote = async (isUpvote: boolean) => {
    // TODO: Implement contract interaction for voting
    console.log("Voting on comment:", { commentId: comment.id, isUpvote })
  }

  const handleReply = async () => {
    // TODO: Implement contract interaction for reply
    console.log("Replying to comment:", { commentId: comment.id, content: replyContent })
    setReplyContent("")
    setIsReplying(false)
  }

  return (
    <div className="space-y-2">
      <div className="rounded-lg border p-4">
        <div className="flex items-center gap-2 text-sm text-muted-foreground mb-2">
          <span>{comment.commenter.slice(0, 6)}...{comment.commenter.slice(-4)}</span>
          <ReputationDisplay address={comment.commenter} className="ml-2" />
          <span>•</span>
          <span>{comment.timestamp}</span>
        </div>
        <p className="mb-3">{comment.content}</p>
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => handleVote(true)}
              className="h-8 w-8 p-0"
            >
              <ArrowBigUp className="h-4 w-4" />
            </Button>
            <span className="text-sm font-medium">{comment.votes}</span>
            <Button
              variant="ghost"
              size="sm"
              onClick={() => handleVote(false)}
              className="h-8 w-8 p-0"
            >
              <ArrowBigDown className="h-4 w-4" />
            </Button>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setIsReplying(!isReplying)}
            className="flex items-center gap-2"
          >
            <Reply className="h-4 w-4" /> Reply
          </Button>
        </div>
        
        {isReplying && (
          <div className="mt-4 space-y-2">
            <Textarea
              placeholder="Write a reply..."
              value={replyContent}
              onChange={(e) => setReplyContent(e.target.value)}
            />
            <div className="flex gap-2">
              <Button size="sm" onClick={handleReply}>Submit</Button>
              <Button size="sm" variant="outline" onClick={() => setIsReplying(false)}>Cancel</Button>
            </div>
          </div>
        )}
      </div>
      
      {comment.replies && (
        <div className="ml-8 space-y-2">
          {comment.replies.map((reply) => (
            <CommentComponent key={reply.id} comment={reply} />
          ))}
        </div>
      )}
    </div>
  )
}

export function CommentsSection({ listingId, comments = mockComments, voteComments = mockVoteComments }: CommentsSectionProps) {
  const [newComment, setNewComment] = useState("")

  const handleAddComment = async () => {
    // TODO: Implement contract interaction
    console.log("Adding comment:", { listingId, content: newComment })
    setNewComment("")
  }

  return (
    <Tabs defaultValue="comments" className="w-full">
      <TabsList className="grid w-full grid-cols-2">
        <TabsTrigger value="comments">Comments</TabsTrigger>
        <TabsTrigger value="vote-comments">Vote Comments</TabsTrigger>
      </TabsList>
      
      <TabsContent value="comments" className="space-y-4">
        <div className="space-y-2">
          <Textarea
            placeholder="Add a comment..."
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
          />
          <Button onClick={handleAddComment}>Add Comment</Button>
        </div>
        <div className="space-y-4">
          {comments.map((comment) => (
            <CommentComponent key={comment.id} comment={comment} />
          ))}
        </div>
      </TabsContent>

      <TabsContent value="vote-comments" className="space-y-4">
        {voteComments.map((comment, index) => (
          <div key={index} className="rounded-lg border p-4">
            <div className="flex items-center gap-2 mb-2">
              <p className="text-sm text-muted-foreground">
                {comment.voter.slice(0, 6)}...{comment.voter.slice(-4)}
              </p>
              <span className={comment.thumbsUp ? "text-green-500" : "text-red-500"}>
                {comment.thumbsUp ? "👍" : "👎"}
              </span>
              <span className="text-sm text-muted-foreground">•</span>
              <span className="text-sm text-muted-foreground">{comment.timestamp}</span>
            </div>
            <p>{comment.comment}</p>
          </div>
        ))}
      </TabsContent>
    </Tabs>
  )
}