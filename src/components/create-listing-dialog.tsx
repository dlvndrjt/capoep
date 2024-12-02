"use client"

import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { useState } from "react"
import { EducationCategory, CategoryLabels } from "@/types/education"

export function CreateListingDialog() {
  const [open, setOpen] = useState(false)
  const [category, setCategory] = useState<EducationCategory | null>(null)

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    // TODO: Implement contract interaction
    setOpen(false)
  }

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button>Create Listing</Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Create New Listing</DialogTitle>
          <DialogDescription>
            Create a new proof of education listing. Fill in the details below.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="category">Category</Label>
            <Select
              value={category?.toString()}
              onValueChange={(value) => setCategory(Number(value) as EducationCategory)}
            >
              <SelectTrigger>
                <SelectValue placeholder="Select a category" />
              </SelectTrigger>
              <SelectContent>
                {Object.entries(CategoryLabels).map(([value, label]) => (
                  <SelectItem key={value} value={value}>
                    {label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label htmlFor="title">Title</Label>
            <Input id="title" placeholder="Enter listing title" required />
          </div>
          <div className="space-y-2">
            <Label htmlFor="details">Details</Label>
            <Textarea
              id="details"
              placeholder="Enter listing details"
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="proofs">Proofs (comma-separated URLs)</Label>
            <Input
              id="proofs"
              placeholder="Enter proof URLs, separated by commas"
              required
            />
          </div>
          <Button type="submit" className="w-full">Create Listing</Button>
        </form>
      </DialogContent>
    </Dialog>
  )
} 