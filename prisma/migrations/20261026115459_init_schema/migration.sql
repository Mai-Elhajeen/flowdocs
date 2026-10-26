-- CreateEnum
CREATE TYPE "MembershipRole" AS ENUM ('ADMIN', 'MEMBER');

-- CreateEnum
CREATE TYPE "MembershipStatus" AS ENUM ('ACTIVE', 'DEACTIVATED');

-- CreateEnum
CREATE TYPE "InvitationStatus" AS ENUM ('PENDING', 'ACCEPTED', 'REVOKED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "ContractReviewStatus" AS ENUM ('PENDING_REVIEW', 'APPROVED');

-- CreateEnum
CREATE TYPE "ProcessingStatus" AS ENUM ('QUEUED', 'PROCESSING', 'SUCCEEDED', 'FAILED');

-- CreateEnum
CREATE TYPE "ProcessingStage" AS ENUM ('TEXT_EXTRACTION', 'OCR', 'AI_EXTRACTION', 'VALIDATION');

-- CreateEnum
CREATE TYPE "ExtractionStatus" AS ENUM ('PROPOSED', 'REVIEWED', 'SUPERSEDED');

-- CreateEnum
CREATE TYPE "DraftSource" AS ENUM ('AI_EXTRACTION', 'MANUAL_EDIT');

-- CreateEnum
CREATE TYPE "DraftStatus" AS ENUM ('OPEN', 'APPROVED', 'DISCARDED');

-- CreateEnum
CREATE TYPE "CycleStatus" AS ENUM ('ACTIVE', 'SUPERSEDED');

-- CreateEnum
CREATE TYPE "TaskStatus" AS ENUM ('OPEN', 'COMPLETED');

-- CreateTable
CREATE TABLE "Organization" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "timezone" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "Organization_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL,
    "clerkUserId" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "displayName" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Membership" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "role" "MembershipRole" NOT NULL,
    "status" "MembershipStatus" NOT NULL,
    "joinedAt" TIMESTAMPTZ(3) NOT NULL,
    "deactivatedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "Membership_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Invitation" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "invitedByMembershipId" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "role" "MembershipRole" NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "status" "InvitationStatus" NOT NULL,
    "expiresAt" TIMESTAMPTZ(3) NOT NULL,
    "acceptedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "Invitation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "actorMembershipId" UUID,
    "entityType" TEXT NOT NULL,
    "entityId" UUID NOT NULL,
    "action" TEXT NOT NULL,
    "oldValues" JSONB,
    "newValues" JSONB,
    "metadata" JSONB,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Contract" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "ownerMembershipId" UUID,
    "title" TEXT NOT NULL,
    "counterpartyName" TEXT,
    "contractNumber" TEXT,
    "startDate" DATE,
    "endDate" DATE,
    "contractValue" DECIMAL(19,4),
    "currency" TEXT,
    "renewalTerms" TEXT,
    "reviewStatus" "ContractReviewStatus" NOT NULL,
    "archivedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "Contract_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DocumentAsset" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "contractId" UUID NOT NULL,
    "uploadedByMembershipId" UUID NOT NULL,
    "storageKey" TEXT NOT NULL,
    "originalFilename" TEXT NOT NULL,
    "mimeType" TEXT NOT NULL,
    "fileSizeBytes" BIGINT NOT NULL,
    "checksum" TEXT,
    "processingStatus" "ProcessingStatus" NOT NULL,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,
    "processedAt" TIMESTAMPTZ(3),
    "uploadedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DocumentAsset_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProcessingAttempt" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "documentAssetId" UUID NOT NULL,
    "attemptNumber" INTEGER NOT NULL,
    "status" "ProcessingStatus" NOT NULL,
    "stage" "ProcessingStage" NOT NULL,
    "provider" TEXT,
    "model" TEXT,
    "errorCode" TEXT,
    "errorMessage" TEXT,
    "startedAt" TIMESTAMPTZ(3) NOT NULL,
    "finishedAt" TIMESTAMPTZ(3),

    CONSTRAINT "ProcessingAttempt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ExtractionResult" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "processingAttemptId" UUID NOT NULL,
    "contractId" UUID NOT NULL,
    "status" "ExtractionStatus" NOT NULL,
    "sourceLanguage" TEXT,
    "extractedPayload" JSONB NOT NULL,
    "validationErrors" JSONB,
    "reviewedByMembershipId" UUID,
    "reviewedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ExtractionResult_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ExtractionEvidence" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "extractionResultId" UUID NOT NULL,
    "fieldName" TEXT NOT NULL,
    "evidenceText" TEXT NOT NULL,
    "pageNumber" INTEGER,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ExtractionEvidence_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ContractReviewDraft" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "contractId" UUID NOT NULL,
    "extractionResultId" UUID,
    "createdByMembershipId" UUID NOT NULL,
    "source" "DraftSource" NOT NULL,
    "status" "DraftStatus" NOT NULL,
    "proposedPayload" JSONB NOT NULL,
    "validationErrors" JSONB,
    "reviewedByMembershipId" UUID,
    "reviewedAt" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "ContractReviewDraft_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ContractEndDateRevision" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "contractId" UUID NOT NULL,
    "previousEndDate" DATE,
    "newEndDate" DATE NOT NULL,
    "reason" TEXT,
    "approvedByMembershipId" UUID NOT NULL,
    "approvedAt" TIMESTAMPTZ(3) NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ContractEndDateRevision_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ContractRenewalCycle" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "contractId" UUID NOT NULL,
    "endDateRevisionId" UUID NOT NULL,
    "approvedEndDate" DATE NOT NULL,
    "dueDate" DATE NOT NULL,
    "cycleNumber" INTEGER NOT NULL,
    "status" "CycleStatus" NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ContractRenewalCycle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Task" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "contractId" UUID NOT NULL,
    "renewalCycleId" UUID NOT NULL,
    "assigneeMembershipId" UUID,
    "status" "TaskStatus" NOT NULL,
    "completedAt" TIMESTAMPTZ(3),
    "completedByMembershipId" UUID,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "Task_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Organization_slug_key" ON "Organization"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "User_clerkUserId_key" ON "User"("clerkUserId");

-- CreateIndex
CREATE INDEX "Membership_userId_idx" ON "Membership"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "Membership_organizationId_id_key" ON "Membership"("organizationId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "Membership_organizationId_userId_key" ON "Membership"("organizationId", "userId");

-- CreateIndex
CREATE UNIQUE INDEX "Invitation_tokenHash_key" ON "Invitation"("tokenHash");

-- CreateIndex
CREATE INDEX "Invitation_organizationId_email_idx" ON "Invitation"("organizationId", "email");

-- CreateIndex
CREATE INDEX "AuditLog_organizationId_createdAt_idx" ON "AuditLog"("organizationId", "createdAt");

-- CreateIndex
CREATE INDEX "AuditLog_organizationId_entityType_entityId_idx" ON "AuditLog"("organizationId", "entityType", "entityId");

-- CreateIndex
CREATE INDEX "Contract_organizationId_archivedAt_reviewStatus_idx" ON "Contract"("organizationId", "archivedAt", "reviewStatus");

-- CreateIndex
CREATE INDEX "Contract_organizationId_endDate_idx" ON "Contract"("organizationId", "endDate");

-- CreateIndex
CREATE UNIQUE INDEX "Contract_organizationId_id_key" ON "Contract"("organizationId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "DocumentAsset_storageKey_key" ON "DocumentAsset"("storageKey");

-- CreateIndex
CREATE INDEX "DocumentAsset_organizationId_contractId_idx" ON "DocumentAsset"("organizationId", "contractId");

-- CreateIndex
CREATE UNIQUE INDEX "DocumentAsset_organizationId_id_key" ON "DocumentAsset"("organizationId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "ProcessingAttempt_organizationId_id_key" ON "ProcessingAttempt"("organizationId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "ProcessingAttempt_documentAssetId_attemptNumber_key" ON "ProcessingAttempt"("documentAssetId", "attemptNumber");

-- CreateIndex
CREATE INDEX "ExtractionResult_contractId_createdAt_idx" ON "ExtractionResult"("contractId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "ExtractionResult_organizationId_id_key" ON "ExtractionResult"("organizationId", "id");

-- CreateIndex
CREATE INDEX "ExtractionEvidence_extractionResultId_fieldName_idx" ON "ExtractionEvidence"("extractionResultId", "fieldName");

-- CreateIndex
CREATE INDEX "ContractReviewDraft_contractId_status_idx" ON "ContractReviewDraft"("contractId", "status");

-- CreateIndex
CREATE INDEX "ContractEndDateRevision_contractId_approvedAt_idx" ON "ContractEndDateRevision"("contractId", "approvedAt");

-- CreateIndex
CREATE UNIQUE INDEX "ContractEndDateRevision_organizationId_id_key" ON "ContractEndDateRevision"("organizationId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "ContractRenewalCycle_organizationId_id_key" ON "ContractRenewalCycle"("organizationId", "id");

-- CreateIndex
CREATE UNIQUE INDEX "ContractRenewalCycle_contractId_cycleNumber_key" ON "ContractRenewalCycle"("contractId", "cycleNumber");

-- CreateIndex
CREATE UNIQUE INDEX "Task_renewalCycleId_key" ON "Task"("renewalCycleId");

-- CreateIndex
CREATE INDEX "Task_organizationId_status_assigneeMembershipId_idx" ON "Task"("organizationId", "status", "assigneeMembershipId");

-- AddForeignKey
ALTER TABLE "Membership" ADD CONSTRAINT "Membership_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Membership" ADD CONSTRAINT "Membership_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invitation" ADD CONSTRAINT "Invitation_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invitation" ADD CONSTRAINT "Invitation_organizationId_invitedByMembershipId_fkey" FOREIGN KEY ("organizationId", "invitedByMembershipId") REFERENCES "Membership"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_organizationId_actorMembershipId_fkey" FOREIGN KEY ("organizationId", "actorMembershipId") REFERENCES "Membership"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Contract" ADD CONSTRAINT "Contract_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Contract" ADD CONSTRAINT "Contract_organizationId_ownerMembershipId_fkey" FOREIGN KEY ("organizationId", "ownerMembershipId") REFERENCES "Membership"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentAsset" ADD CONSTRAINT "DocumentAsset_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentAsset" ADD CONSTRAINT "DocumentAsset_organizationId_contractId_fkey" FOREIGN KEY ("organizationId", "contractId") REFERENCES "Contract"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DocumentAsset" ADD CONSTRAINT "DocumentAsset_organizationId_uploadedByMembershipId_fkey" FOREIGN KEY ("organizationId", "uploadedByMembershipId") REFERENCES "Membership"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProcessingAttempt" ADD CONSTRAINT "ProcessingAttempt_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProcessingAttempt" ADD CONSTRAINT "ProcessingAttempt_organizationId_documentAssetId_fkey" FOREIGN KEY ("organizationId", "documentAssetId") REFERENCES "DocumentAsset"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExtractionResult" ADD CONSTRAINT "ExtractionResult_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExtractionResult" ADD CONSTRAINT "ExtractionResult_organizationId_processingAttemptId_fkey" FOREIGN KEY ("organizationId", "processingAttemptId") REFERENCES "ProcessingAttempt"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExtractionResult" ADD CONSTRAINT "ExtractionResult_organizationId_contractId_fkey" FOREIGN KEY ("organizationId", "contractId") REFERENCES "Contract"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExtractionResult" ADD CONSTRAINT "ExtractionResult_organizationId_reviewedByMembershipId_fkey" FOREIGN KEY ("organizationId", "reviewedByMembershipId") REFERENCES "Membership"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExtractionEvidence" ADD CONSTRAINT "ExtractionEvidence_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ExtractionEvidence" ADD CONSTRAINT "ExtractionEvidence_organizationId_extractionResultId_fkey" FOREIGN KEY ("organizationId", "extractionResultId") REFERENCES "ExtractionResult"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractReviewDraft" ADD CONSTRAINT "ContractReviewDraft_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractReviewDraft" ADD CONSTRAINT "ContractReviewDraft_organizationId_contractId_fkey" FOREIGN KEY ("organizationId", "contractId") REFERENCES "Contract"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractReviewDraft" ADD CONSTRAINT "ContractReviewDraft_organizationId_extractionResultId_fkey" FOREIGN KEY ("organizationId", "extractionResultId") REFERENCES "ExtractionResult"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractReviewDraft" ADD CONSTRAINT "ContractReviewDraft_organizationId_createdByMembershipId_fkey" FOREIGN KEY ("organizationId", "createdByMembershipId") REFERENCES "Membership"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractReviewDraft" ADD CONSTRAINT "ContractReviewDraft_organizationId_reviewedByMembershipId_fkey" FOREIGN KEY ("organizationId", "reviewedByMembershipId") REFERENCES "Membership"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractEndDateRevision" ADD CONSTRAINT "ContractEndDateRevision_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractEndDateRevision" ADD CONSTRAINT "ContractEndDateRevision_organizationId_contractId_fkey" FOREIGN KEY ("organizationId", "contractId") REFERENCES "Contract"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractEndDateRevision" ADD CONSTRAINT "ContractEndDateRevision_organizationId_approvedByMembershi_fkey" FOREIGN KEY ("organizationId", "approvedByMembershipId") REFERENCES "Membership"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractRenewalCycle" ADD CONSTRAINT "ContractRenewalCycle_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractRenewalCycle" ADD CONSTRAINT "ContractRenewalCycle_organizationId_contractId_fkey" FOREIGN KEY ("organizationId", "contractId") REFERENCES "Contract"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ContractRenewalCycle" ADD CONSTRAINT "ContractRenewalCycle_organizationId_endDateRevisionId_fkey" FOREIGN KEY ("organizationId", "endDateRevisionId") REFERENCES "ContractEndDateRevision"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Task" ADD CONSTRAINT "Task_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Task" ADD CONSTRAINT "Task_organizationId_contractId_fkey" FOREIGN KEY ("organizationId", "contractId") REFERENCES "Contract"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Task" ADD CONSTRAINT "Task_organizationId_renewalCycleId_fkey" FOREIGN KEY ("organizationId", "renewalCycleId") REFERENCES "ContractRenewalCycle"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Task" ADD CONSTRAINT "Task_organizationId_assigneeMembershipId_fkey" FOREIGN KEY ("organizationId", "assigneeMembershipId") REFERENCES "Membership"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Task" ADD CONSTRAINT "Task_organizationId_completedByMembershipId_fkey" FOREIGN KEY ("organizationId", "completedByMembershipId") REFERENCES "Membership"("organizationId", "id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- One pending invitation per organization and email (case-insensitive)
CREATE UNIQUE INDEX "Invitation_pending_org_email_key"
ON "Invitation" ("organizationId", lower("email"))
WHERE "status" = 'PENDING';