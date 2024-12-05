import { Card, CardHeader, CardContent } from "@/components/ui/card"
import { Skeleton } from "@/components/ui/skeleton"

export function ListingSkeleton() {
  return (
    <Card className="group cursor-pointer hover:bg-accent">
      <CardHeader>
        <div className="flex items-start justify-between">
          <div className="space-y-2 w-full">
            <Skeleton className="h-6 w-[70%]" /> {/* Title */}
            <div className="flex flex-wrap items-center gap-2">
              <Skeleton className="h-5 w-20" /> {/* Category Badge */}
              <Skeleton className="h-5 w-16" /> {/* Minted Badge */}
              <div className="flex items-center gap-2">
                <Skeleton className="h-5 w-12" /> {/* Upvotes */}
                <Skeleton className="h-5 w-12" /> {/* Downvotes */}
              </div>
            </div>
            <div className="flex items-center gap-2">
              <Skeleton className="h-4 w-32" /> {/* Creator address */}
              <Skeleton className="h-4 w-16" /> {/* Reputation */}
            </div>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-2">
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-[90%]" />
        </div>
        <Skeleton className="h-4 w-24 mt-2" /> {/* Date */}
      </CardContent>
    </Card>
  )
} 