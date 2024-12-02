"use client"

import { useEffect, useState } from "react"
import { Badge } from "@/components/ui/badge"

interface ReputationDisplayProps {
  address: string
  className?: string
}

export function ReputationDisplay({ address, className }: ReputationDisplayProps) {
  const [reputation, setReputation] = useState<number>(0)

  useEffect(() => {
    const fetchReputation = async () => {
      try {
        // TODO: Implement contract call
        // const rep = await contract.getUserReputation(address)
        // setReputation(rep)
      } catch (error) {
        console.error("Error fetching reputation:", error)
      }
    }

    fetchReputation()
  }, [address])

  return (
    <Badge 
      variant={reputation >= 0 ? "default" : "destructive"}
      className={className}
    >
      {reputation} karma
    </Badge>
  )
} 