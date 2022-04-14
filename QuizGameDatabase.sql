Create database QuizGame;
GO

use QuizGame;

create table Category
(
	category_id int identity(1,1) primary key not null,
	category_name nvarchar(25)

)

create table Questions
(
	question_id int identity(1,1) primary key,
	category_id int foreign key references Category(category_id),
	content nvarchar(100), 
	modify_date datetime default getdate() 
)

create table Possible_Answers
(
	answer_id int identity(1,1) primary key,
	answer nvarchar(20),  --nvarchar
	question_id int foreign key references Questions(question_id),
	correct_answer int check(correct_answer between 0 and 1) -- 0 to false, 1 to true
	
)

create table Player
(
	player_id int identity(1,1) primary key not null,
	nick nvarchar(20),
	score int default 0,
)

create table Player_Questions
(
	player_id int foreign key references Player(player_id) not null,
	question_id int foreign key references Questions(question_id) 
)

create table Player_Answers
(
	player_id int foreign key references Player(player_id),
	question_id int foreign key references Questions(question_id),
	answer_id int foreign key references Possible_Answers(answer_id)
)

insert into Category (category_name)values
('Historia'),
('IT'),
('Geografia'),
('Fizyka i Chemia'),
('Matematyka'),
('Jêzyk Angielski'),
('Bazy danych')

insert into Player (Nick)values
('Nick1'),
('Nick2'),
('Nick3'),
('Nick4')
go

--procedure which you can use to add Question

Create or alter procedure dbo.AddQuestion  
@category_id int,
@content nvarchar(25)

as

if exists (select content from Questions where content = @content)
begin
raiserror('This question already exists, insert different value',11,1)
return -1
end

if exists (select* from Category
where category_id = @category_id)
begin
insert into Questions (category_id, content) values(@category_id, @content)

end

else
begin
raiserror('This category does not exist, insert different value',11,1)
return -1
end

go

--procedure which adds answers with correct answer and more than 3 answer is not allowed 

Create or alter procedure dbo.AddPossibleAnswer 
@answer nvarchar(25),
@is_answer_correct int, 
@question_id int
as

if not exists (select answer from Possible_Answers as pa
				join Questions as q on pa.question_id = q.question_id
				where answer = @answer and q.question_id = @question_id )
begin

if exists (select question_id from Questions where question_id = @question_id)
	begin
	
declare @answer_count as int
select @answer_count = count(question_id) from Possible_Answers where question_id = @question_id --sprawdza liczbe pytan do istniejacego pytania

if (@answer_count < 3)
	begin
insert into Possible_Answers (question_id, answer, correct_answer)
values(@question_id, @answer, @is_answer_correct)
	end
else
	begin
raiserror('there is already 3 answers',11,1)
return -1
	end

	end

	end
	else
	begin
raiserror('the answer already exists',11,1)
return -1
	end

go

go

--this procedure draws lots questions for player (they cannot be the same)

create or alter procedure dbo.GetQuestionForPlayer
@player_id int,
@player_questions_quantity int -- number of questions that we want draw by lot

as
declare @question_id int
declare @random_record int
declare @total_question_count int -- current number of questions in database

select @total_question_count = count(question_id) from Questions 

declare @i as int = 0
while(@i < @player_questions_quantity)
begin
set @random_record = cast(Rand()*@total_question_count+1 as int) -- drawing by lot number between 1 and whole amonut of questions
set @question_id = @random_record 

if exists (select*from Player_Questions where player_id = @player_id and question_id = @question_id)
begin
continue
end
else
insert into Player_Questions values (@player_id, @question_id)
set @i += 1
end

go

--this trigger adds one point for player who answered correctly 


CREATE or alter TRIGGER AddScore  
ON Player_Answers
for insert

as
declare @player_id as int
select @player_id = player_id from inserted

declare @player_answer as int
select @player_answer = answer_id from inserted

declare @correct_answer as int
select @correct_answer = answer_id from Possible_Answers where correct_answer = 1

begin
if (@player_answer = @correct_answer)
begin
	update Player
	set score += 1
	where player_id = @player_id
end

end

----exemplary using of procedures

--exec AddQuestion 1,'W którym wieku by³ chrzest polski'
--exec AddQuestion 2,'co to jest C#'
--exec AddQuestion 3,'Jaka jest stolica Polski'

--exec AddPossibleAnswer 'Warszawa',1,1
--exec AddPossibleAnswer 'Bruksela',0,1
--exec AddPossibleAnswer 'Kraków',0,1

--exec GetQuestionForPlayer 1,2 -- dodaje 2 pytania do gracza nr.1 


-- --exemplary using of trigger when player answers correctly
 
--insert into Player_Answers values (1,1,1)
--select*from Player
