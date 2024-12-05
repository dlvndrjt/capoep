"use client"

import { useEffect, useState } from "react"
import { Badge } from "@/components/ui/badge"
import { Skeleton } from "@/components/ui/skeleton"

interface ReputationDisplayProps {
  address: string
  className?: string
}

export function ReputationDisplay({ address, className }: ReputationDisplayProps) {
  const [reputation, setReputation] = useState<number | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchReputation = async () => {
      try {
        setLoading(true)
        // TODO: Implement contract call
        // const rep = await contract.getUserReputation(address)
        // setReputation(rep)
        setReputation(Math.floor(Math.random() * 100)) // Mock data
      } catch (error) {
        console.error("Error fetching reputation:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchReputation()
  }, [address])

  if (loading) {
    return <Skeleton className="h-5 w-16" />
  }

  return (
    <Badge 
      variant={reputation >= 0 ? "default" : "destructive"}
      className={className}
    >
      {reputation} karma
    </Badge>
  )
} 