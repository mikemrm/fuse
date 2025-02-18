-- name: GetRepoImportByID :one
SELECT * FROM mergestat.repo_imports
WHERE id = $1 LIMIT 1;

-- name: ListRepoImportsDueForImport :many
WITH dequeued AS (
	UPDATE mergestat.repo_imports SET last_import_started_at = now()
	WHERE id IN (
		SELECT id FROM mergestat.repo_imports AS t
		WHERE
			(now() - t.last_import > t.import_interval OR t.last_import IS NULL)
			AND
			(now() - t.last_import_started_at > t.import_interval OR t.last_import_started_at IS NULL)
		ORDER BY last_import ASC
		FOR UPDATE SKIP LOCKED
	) RETURNING *
)
SELECT id, created_at, updated_at, type, settings FROM dequeued;
;

-- name: UpsertRepo :exec
INSERT INTO public.repos (repo, is_github, repo_import_id) VALUES($1, $2, $3)
ON CONFLICT (repo, (ref IS NULL)) WHERE ref IS NULL
DO UPDATE SET tags = (
    SELECT COALESCE(jsonb_agg(DISTINCT x), jsonb_build_array()) FROM jsonb_array_elements(repos.tags || $4) x LIMIT 1
);

-- name: MarkRepoImportAsUpdated :exec
UPDATE mergestat.repo_imports SET last_import = now() WHERE id = $1;

-- name: DequeueSyncJob :one
WITH dequeued AS (
	UPDATE mergestat.repo_sync_queue SET status = 'RUNNING'
	WHERE id IN (
		SELECT id FROM mergestat.repo_sync_queue
		WHERE status = 'QUEUED'
		ORDER BY repo_sync_queue.created_at ASC LIMIT 1 FOR UPDATE SKIP LOCKED
	) RETURNING id, created_at, status, repo_sync_id
)
SELECT
	dequeued.*,
	repo_syncs.*,
	repos.repo,
	repos.ref,
	repos.is_github,
	repos.settings AS repo_settings
FROM dequeued
JOIN mergestat.repo_syncs ON mergestat.repo_syncs.id = dequeued.repo_sync_id
JOIN repos ON repos.id = mergestat.repo_syncs.repo_id
;

-- name: UpsertGitHubRepoInfo :exec
INSERT INTO public.github_repo_info (repo_id, owner, name, metadata) VALUES($1, $2, $3, $4)
ON CONFLICT ON CONSTRAINT github_repo_info_pkey
DO UPDATE SET metadata = $4;

-- name: InsertSyncJobLog :exec
INSERT INTO mergestat.repo_sync_logs (log_type, message, repo_sync_queue_id) VALUES ($1, $2, $3);

-- name: SetSyncJobStatus :exec
UPDATE mergestat.repo_sync_queue SET status = $1 WHERE id = $2;

-- name: EnqueueAllSyncs :exec
INSERT INTO mergestat.repo_sync_queue (repo_sync_id, status)
SELECT id, 'QUEUED' FROM mergestat.repo_syncs;