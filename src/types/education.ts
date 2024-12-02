export enum EducationCategory {
    STUDENT = 0,
    EDUCATOR = 1,
    CONTENT_CREATOR = 2,
    INSTITUTION = 3,
    RESEARCHER = 4,
    MENTOR = 5,
    COMMUNITY_EDUCATOR = 6
}

export const CategoryLabels: Record<EducationCategory, string> = {
    [EducationCategory.STUDENT]: "Student",
    [EducationCategory.EDUCATOR]: "Educator",
    [EducationCategory.CONTENT_CREATOR]: "Content Creator",
    [EducationCategory.INSTITUTION]: "Institution",
    [EducationCategory.RESEARCHER]: "Researcher",
    [EducationCategory.MENTOR]: "Mentor",
    [EducationCategory.COMMUNITY_EDUCATOR]: "Community Educator"
} 