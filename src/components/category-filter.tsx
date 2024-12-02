"use client"

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { EducationCategory, CategoryLabels } from "@/types/education"

interface CategoryFilterProps {
  selectedCategory: EducationCategory | null
  onCategoryChange: (category: EducationCategory | null) => void
}

export function CategoryFilter({ selectedCategory, onCategoryChange }: CategoryFilterProps) {
  return (
    <Select
      value={selectedCategory?.toString() ?? "all"}
      onValueChange={(value) => 
        onCategoryChange(value === "all" ? null : Number(value) as EducationCategory)
      }
    >
      <SelectTrigger className="w-[200px]">
        <SelectValue placeholder="All Categories" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem value="all">All Categories</SelectItem>
        {Object.entries(CategoryLabels).map(([value, label]) => (
          <SelectItem key={value} value={value}>
            {label}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  )
} 